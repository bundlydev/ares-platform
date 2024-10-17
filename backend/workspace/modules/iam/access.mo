// Base Modules
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Array "mo:base/Array";
import Principal "mo:base/Principal";

// Mops Modules
import Map "mo:map/Map";
import { phash } "mo:map/Map";

// Cutom Modules
import RoleModule "./role";
import PolicyModule "./policy";

import Types "./types";

module AccessService {
	public type AccessIdentityType = {
		#orchestrator;
		#user;
		#app;
	};

	public type Access = {
		identity : Principal;
		roleId : Text;
		itype : AccessIdentityType;
	};

	public type AccessCollection = Map.Map<Principal, Access>;

	// Errors
	public let ACCESS_ALREADY_EXISTS_ERROR = "Access already exists";
	public let ACCESS_DOES_NOT_EXIST_ERROR = "Access does not exist";
	public let ACCESS_AND_ROLE_DOES_NOT_EXIST_ERROR = "Access and role do not exist";

	public class AccessService(_repository : AccessCollection, policyService : PolicyModule.PolicyService, roleService : RoleModule.RoleService) {
		public func getAll() : [Access] {
			let accessIter = Map.vals<Principal, Access>(_repository);
			let accessArray = Iter.toArray(accessIter);

			return accessArray;
		};

		public func getById(aid : Principal) : ?Access {
			return Map.get<Principal, Access>(_repository, phash, aid);
		};

		public func hasPermission(identity : Principal, accessType : Types.AccessType) : Bool {
			// if (Principal.equal(identity, context.creator)) return true;
			// if (Principal.equal(identity, context.owner)) return true;

			switch (accessType) {
				case (#anonymous) return true;
				case (#permission(permission)) {
					if (permission == "") return false;

					let maybeAccess = getById(identity);

					switch (maybeAccess) {
						case (?access) {
							let maybeRole = roleService.getById(access.roleId);

							switch (maybeRole) {
								case (?role) {
									var isAllowed = false;

									// Iterate over all policies associated with the role
									for (policyId in role.policies.vals()) {
										let maybePolicy = policyService.getById(policyId);

										switch (maybePolicy) {
											case (?policy) {
												// Evaluate each statement in the policy
												for (statement in policy.statements.vals()) {
													switch (statement.action, statement.effect) {
														case (#all, #allow) { isAllowed := true };
														case (#all, #deny) { return false };
														case (#list(accessPermissions), #allow) {
															if (Array.find<Text>(accessPermissions, func x = x == permission) != null) {
																isAllowed := true;
															};
														};
														case (#list(accessPermissions), #deny) {
															if (Array.find<Text>(accessPermissions, func x = x == permission) != null) {
																return false;
															};
														};
													};
												};
											};
											case null { /* Policy does not exist; continue to the next */ };
										};
									};

									return isAllowed;
								};
								case null { return false }; // Role does not exist
							};
						};
						case null { return false }; // Access does not exist
					};
				};
			};
		};

		type CreateAccessData = {
			identity : Principal;
			roleId : Text;
			itype : AccessIdentityType;
		};

		public func create(data : CreateAccessData) : async Access {
			let maybeAccess = getById(data.identity);

			if (maybeAccess != null) {
				throw Error.reject(ACCESS_ALREADY_EXISTS_ERROR);
			};

			let maybeRole = roleService.getById(data.roleId);

			if (maybeRole == null) {
				throw Error.reject(RoleModule.ROLE_DOES_NOT_EXIST_ERROR);
			};

			ignore Map.put(_repository, phash, data.identity, data);

			return data;
		};

		public func delete(identity : Principal) : async Access {
			let maybeAccess = getById(identity);

			switch (maybeAccess) {
				case (?access) {
					ignore Map.remove<Principal, Access>(_repository, phash, identity);

					return access;
				};
				case null {
					throw Error.reject(ACCESS_DOES_NOT_EXIST_ERROR);
				};
			};
		};

		public func changeRole(identity : Principal, roleId : Text) : async () {
			let maybeAccess = getById(identity);
			let maybeRole = roleService.getById(roleId);

			switch (maybeAccess, maybeRole) {
				case (?access, ?_role) {
					let updatedAccess = { access with roleId };
					ignore Map.put(_repository, phash, identity, updatedAccess);
				};
				case (null, ?_) {
					throw Error.reject(RoleModule.ROLE_DOES_NOT_EXIST_ERROR);
				};
				case (?_, null) {
					throw Error.reject(ACCESS_DOES_NOT_EXIST_ERROR);
				};
				case (null, null) {
					throw Error.reject(ACCESS_AND_ROLE_DOES_NOT_EXIST_ERROR);
				};
			};
		};
	};
};
