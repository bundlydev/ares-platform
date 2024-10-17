// Base Modules
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Array "mo:base/Array";

// Mops Modules
import Map "mo:map/Map";
import { thash } "mo:map/Map";

// Custom Modules
import PolicyModule "./policy";

module RoleModule {
	public type Role = {
		rid : Text;
		name : Text;
		description : Text;
		policies : [Text];
	};

	public type RoleCollection = Map.Map<Text, Role>;

	// Errors
	public let ROLE_ALREADY_EXISTS_ERROR = "Role already exists";
	public let ROLE_DOES_NOT_EXIST_ERROR = "Role does not exist";
	public let ROLE_POLICY_ALREADY_GRANTED_ERROR = "Policy already granted";
	public let ROLE_OR_POLICY_DOES_NOT_EXIST_ERROR = "Role and policy do not exist";

	public class RoleService(_repository : RoleCollection, policyService : PolicyModule.PolicyService) {
		public func getAll() : [Role] {
			let roleIter = Map.vals<Text, Role>(_repository);
			let roleArray = Iter.toArray(roleIter);

			return roleArray;
		};

		public func getById(rid : Text) : ?Role {
			return Map.get<Text, Role>(_repository, thash, rid);
		};

		private func setId(name : Text) : Text {
			// TODO: Generate name
			// Should remove spaces and special characters
			let id = name;
			return id;
		};

		type CreateRoleData = {
			name : Text;
			description : Text;
			policies : [Text];
		};

		public func create(data : CreateRoleData) : async Role {
			for (policyId in data.policies.vals()) {
				let maybePolicy = policyService.getById(policyId);

				if (maybePolicy == null) {
					throw Error.reject(PolicyModule.POLICY_DOES_NOT_EXIST_ERROR);
				};
			};

			let rid = setId(data.name);

			let maybeExistingRole = getById(rid);

			if (maybeExistingRole == null) {
				let newRole = { data with rid };

				ignore Map.put(_repository, thash, rid, newRole);

				return newRole;
			} else {
				throw Error.reject(ROLE_ALREADY_EXISTS_ERROR);
			};
		};

		public func delete(rid : Text) : async Role {
			switch (Map.remove(_repository, thash, rid)) {
				case (?role) return role;
				case null throw Error.reject(ROLE_DOES_NOT_EXIST_ERROR);
			};
		};

		public func addPolicy(rid : Text, policyId : Text) : async () {
			let maybeRole = getById(rid);
			let maybePolicy = policyService.getById(policyId);

			switch (maybeRole, maybePolicy) {
				case (?role, ?_policy) {
					let policyAlreadyGranted = Array.find<Text>(
						role.policies,
						func(p) {
							p == policyId;
						},
					);

					switch (policyAlreadyGranted) {
						case (?_) { throw Error.reject(ROLE_POLICY_ALREADY_GRANTED_ERROR) };
						case null {
							let updatedRole = { role with policies = Array.append(role.policies, [policyId]) };
							ignore Map.put(_repository, thash, rid, updatedRole);
						};
					};
				};
				case (?_role, null) {
					throw Error.reject(PolicyModule.POLICY_DOES_NOT_EXIST_ERROR);
				};
				case (null, ?_policy) {
					throw Error.reject(ROLE_DOES_NOT_EXIST_ERROR);
				};
				case (null, null) {
					throw Error.reject(ROLE_OR_POLICY_DOES_NOT_EXIST_ERROR);
				};
			};
		};

		public func removePolicy(rid : Text, policyId : Text) : async () {
			let maybeRole = getById(rid);
			let maybePolicy = policyService.getById(policyId);

			switch (maybeRole, maybePolicy) {
				case (?role, ?policy) {
					let updatedPolicies = Array.filter<Text>(
						role.policies,
						func(p) {
							p != policy.pid;
						},
					);

					let updatedRole = { role with policies = updatedPolicies };

					ignore Map.put(_repository, thash, rid, updatedRole);
				};
				case (?_role, null) {
					throw Error.reject(PolicyModule.POLICY_DOES_NOT_EXIST_ERROR);
				};
				case (null, ?_policy) {
					throw Error.reject(ROLE_DOES_NOT_EXIST_ERROR);
				};
				case (null, null) {
					throw Error.reject(ROLE_OR_POLICY_DOES_NOT_EXIST_ERROR);
				};
			};
		};
	};
};
