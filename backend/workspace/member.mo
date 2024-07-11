import Principal "mo:base/Principal";
import Map "mo:map/Map";
import { phash } "mo:map/Map";

module {
	public type Member = {
		id : Principal;
		roleId : Nat;
	};

	public type Members = Map.Map<Principal, Member>;

	public class MemberService(_members : Members) {
		public func add(userId : Principal, roleId : Nat) : () {
			let newMember = { id = userId; roleId = roleId };

			Map.set<Principal, Member>(_members, phash, userId, newMember);
		};

		public func getAll() : Members {
			return _members;
		};
	};
};
