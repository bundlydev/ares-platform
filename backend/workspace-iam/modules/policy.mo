// Base Modules
import Iter "mo:base/Iter";
import Error "mo:base/Error";

// Mops Modules
import Map "mo:map/Map";
import { thash } "mo:map/Map";

module PolicyModule {
	public type AccessPermission = Text;
	public type PolicyStatementAction = {
		#all;
		#list : [AccessPermission];
	};

	public type PolicyStatement = {
		effect : {
			#allow;
			#denied;
		};
		action : PolicyStatementAction;
		// TODO: Implement resource validation
		// resource : {
		//   #all;
		//   #list : [Text];
		// };
	};

	public type PolicyType = {
		#managed;
		#custom;
	};

	public type Policy = {
		pid : Text;
		ptype : PolicyType;
		statements : [PolicyStatement];
	};

	public type PolicyCollection = Map.Map<Text, Policy>;

	// Errors
	public let POLICY_DOES_NOT_EXIST_ERROR = "Policy does not exist";
	public let POLICY_ALREADY_EXISTS_ERROR = "Policy already added";
	public let POLICY_MANAGED_POLICY_CANNOT_BE_REMOVED_ERROR = "Cannot remove managed policy";

	public let defaultPolicies : [Policy] = [
		{
			pid = "AdministratorAccess";
			ptype = #managed;
			statements = [{
				effect = #allow;
				action = #all;
			}];
		},
	];

	public class PolicyService(_storage : PolicyCollection) {
		public func getAll() : [Policy] {
			let policyIter = Map.vals<Text, Policy>(_storage);
			let policyArray = Iter.toArray(policyIter);

			return policyArray;
		};

		public func getById(pid : Text) : ?Policy {
			return Map.get<Text, Policy>(_storage, thash, pid);
		};

		public func create(newPolicy : Policy) : async () {
			// TODO: Validate policy pid format (no spaces, special characters, etc)

			if (getById(newPolicy.pid) != null) {
				throw Error.reject(POLICY_ALREADY_EXISTS_ERROR);
			};

			ignore Map.put<Text, Policy>(_storage, thash, newPolicy.pid, newPolicy);
		};

		public func delete(pid : Text) : async Policy {
			switch (getById(pid)) {
				case (?policy) {
					if (policy.ptype == #managed) {
						throw Error.reject(POLICY_MANAGED_POLICY_CANNOT_BE_REMOVED_ERROR);
					};

					ignore Map.remove<Text, Policy>(_storage, thash, pid);

					return policy;
				};
				case null { throw Error.reject(POLICY_DOES_NOT_EXIST_ERROR) };
			};
		};
	};
};
