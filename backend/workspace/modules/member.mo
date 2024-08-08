// Base Modules
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Iter "mo:base/Iter";

// Mops Modules
import Map "mo:map/Map";
import { phash } "mo:map/Map";

// Local Modules
import WebhookModule "./webhook";
import RoleModule "./role";

module MemberModule {
	public type MemberEntity = {
		id : Principal;
		roleId : Nat;
	};

	public type MemberStorage = Map.Map<Principal, MemberEntity>;

	public type AddMemberResultOk = ();

	public type AddMemberResultErr = {
		#memberAlreadyRegistered;
	};

	public type RemoveMemberResultOk = ();

	public type RemoveMemberResultErr = {
		#ownersCannotBeRemoved;
		#memberNotFound;
	};

	public type RemoveMemberResult = Result.Result<RemoveMemberResultOk, RemoveMemberResultErr>;

	public class MemberService(_storage : MemberStorage, webhookService : WebhookModule.WebhookService) {
		public func getAll() : MemberStorage {
			return _storage;
		};

		public func getAllArray() : [MemberEntity] {
			return Iter.toArray(Map.vals(_storage));
		};

		public func add(userId : Principal, roleId : Nat) : async Result.Result<AddMemberResultOk, AddMemberResultErr> {
			let existingMember = Map.get<Principal, MemberEntity>(_storage, phash, userId);

			if (existingMember != null) {
				return #err(#memberAlreadyRegistered);
			};

			let newMember = { id = userId; roleId = roleId };

			Map.set<Principal, MemberEntity>(_storage, phash, userId, newMember);

			let memberAddedEvent = { userId; roleId };

			ignore webhookService.emit(#memberAdded(memberAddedEvent));

			return #ok();
		};

		public func remove(memberId : Principal) : async RemoveMemberResult {
			let existingMember = Map.get<Principal, MemberEntity>(_storage, phash, memberId);

			switch existingMember {
				case (null) #err(#memberNotFound);
				case (?member) {
					if (member.roleId == RoleModule.DEFAULT_OWNER_ROLE_ID) {
						#err(#ownersCannotBeRemoved);
					} else {
						ignore Map.remove<Principal, MemberEntity>(_storage, phash, memberId);

						let memberRemovedEvent = { userId = memberId };

						ignore webhookService.emit(#memberRemoved(memberRemovedEvent));

						#ok();
					};
				};
			};
		};

		public func isMember(memberId : Principal) : Bool {
			return Map.has<Principal, MemberEntity>(_storage, phash, memberId);
		};

		public func isOwner(memberId : Principal) : Bool {
			let existingMember = Map.get<Principal, MemberEntity>(_storage, phash, memberId);

			switch existingMember {
				case (null) false;
				case (?member) member.roleId == RoleModule.DEFAULT_OWNER_ROLE_ID;
			};
		};

		public func isAdmin(memberId : Principal) : Bool {
			let existingMember = Map.get<Principal, MemberEntity>(_storage, phash, memberId);

			switch existingMember {
				case (null) false;
				case (?member) member.roleId == RoleModule.DEFAULT_ADMIN_ROLE_ID;
			};
		};
	};
};
