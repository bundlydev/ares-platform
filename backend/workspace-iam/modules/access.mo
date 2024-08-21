// Base Modules
import Iter "mo:base/Iter";
import Error "mo:base/Error";

// Mops Modules
import Map "mo:map/Map";
import { phash } "mo:map/Map";

// Cutom Modules
import RoleModule "./role";
import PolicyModule "./policy";

module AccessModule {
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

	public class AccessService(_storage : AccessCollection, policyService : PolicyModule.PolicyService, roleService : RoleModule.RoleService) {
		public func getAll() : [Access] {
			let accessIter = Map.vals<Principal, Access>(_storage);
			let accessArray = Iter.toArray(accessIter);

			return accessArray;
		};

		public func getById(aid : Principal) : ?Access {
			return Map.get<Principal, Access>(_storage, phash, aid);
		};

		public func hasPermission(identity : Principal, action : Text) : Bool {
			let maybeAccess = getById(identity);

			switch (maybeAccess) {
				case (?access) {
					let maybeRole = roleService.getById(access.roleId);

					switch (maybeRole) {
						case (?role) {
							for (policyId in role.policies.vals()) {
								let maybePolicy = policyService.getById(policyId);

								switch (maybePolicy) {
									case (?policy) {
										for (statement in policy.statements.vals()) {
											switch (statement.action, statement.effect) {
												case ("*", #allow) { return true };
												case ("*", #denied) { return false };
												case (_) {};
											};

											// TODO: Move this to above switch
											if (statement.action == action) {
												switch (statement.effect) {
													case (#allow) { return true };
													case (#denied) { return false };
												};
											};
										};
									};
									case null { return false };
								};
							};
						};
						case null { return false };
					};
				};
				case null { return false };
			};

			return false;
		};

		public func add(identity : Principal, roleId : Text, itype : AccessIdentityType) : async Access {
			let maybeAccess = getById(identity);

			if (maybeAccess != null) {
				throw Error.reject(ACCESS_ALREADY_EXISTS_ERROR);
			};

			let maybeRole = roleService.getById(roleId);

			if (maybeRole == null) {
				throw Error.reject(RoleModule.ROLE_DOES_NOT_EXIST_ERROR);
			};

			let access : Access = {
				identity;
				roleId;
				itype;
			};

			ignore Map.put(_storage, phash, identity, access);

			return access;
		};

		public func remove(identity : Principal) : async Access {
			let maybeAccess = getById(identity);

			switch (maybeAccess) {
				case (?access) {
					ignore Map.remove<Principal, Access>(_storage, phash, identity);

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
					ignore Map.put(_storage, phash, identity, updatedAccess);
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
