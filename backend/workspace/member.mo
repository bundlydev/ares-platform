import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Map "mo:map/Map";
import { phash } "mo:map/Map";

import Role "./role";

module {
	public type Member = {
		id : Principal;
		roleId : Nat;
	};

	public type Members = Map.Map<Principal, Member>;

	public type AddMemberResultOk = Member;

	public type AddMemberResultErr = {
		#memberAlreadyRegistered;
	};

	public type RemoveMemberResultOk = ();

	public type RemoveMemberResultErr = {
		#ownersCannotBeRemoved;
		#memberNotFound;
	};

	public type RemoveMemberResult = Result.Result<RemoveMemberResultOk, RemoveMemberResultErr>;

	public class MemberService(_members : Members) {
		public func getAll() : Members {
			return _members;
		};

		public func add(userId : Principal, roleId : Nat) : Result.Result<AddMemberResultOk, AddMemberResultErr> {
			let existingMember = Map.get<Principal, Member>(_members, phash, userId);

			if (existingMember != null) {
				return #err(#memberAlreadyRegistered);
			};

			let newMember = { id = userId; roleId = roleId };

			Map.set<Principal, Member>(_members, phash, userId, newMember);

			return #ok(newMember);
		};

		public func remove(memberId : Principal) : RemoveMemberResult {
			let existingMember = Map.get<Principal, Member>(_members, phash, memberId);

			switch existingMember {
				case (null) #err(#memberNotFound);
				case (?member) {
					if (member.roleId == Role.DEFAULT_OWNER_ROLE_ID) {
						#err(#ownersCannotBeRemoved);
					} else {
						ignore Map.remove<Principal, Member>(_members, phash, memberId);

						#ok();
					};
				};
			};
		};
	};
};
