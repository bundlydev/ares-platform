// Base Modules
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import Cycles "mo:base/ExperimentalCycles";

// Mops Modules
import IC "mo:ic";

// Custom Modules
import Member "./member";
import Role "./role";

shared ({ caller = creator }) actor class WorkspaceActorClass(name : Text, owner : Principal) = this {
	// Database
	private stable let _creator : Principal = creator;
	private stable var _name : Text = name;
	private stable let _roles = Map.new<Nat, Role.Role>();
	private stable let _members = Map.new<Principal, Member.Member>();

	// Services
	private let ic = actor ("aaaaa-aa") : IC.Service;
	private let roleService = Role.RoleService(_roles);
	private let memberService = Member.MemberService(_members);

	// Init Start
	ignore memberService.add(owner, Role.DEFAULT_OWNER_ROLE_ID);
	// Init End

	private func hasAccess(caller : Principal) : Bool {
		if (Principal.isAnonymous(caller)) return false;

		if (Principal.equal(caller, _creator)) return true;

		return false;
	};

	type DeleteResponseOk = {
		refundedCycles : Nat;
	};

	type DeleteResponseErr = {
		#unauthorized;
	};

	type DeleteResponse = Result.Result<DeleteResponseOk, DeleteResponseErr>;

	public shared ({ caller }) func onDelete(requester : Principal) : async DeleteResponse {
		if (not hasAccess(caller)) {
			return #err(#unauthorized);
		};

		switch (memberService.isOwner(requester)) {
			case (false) #err(#unauthorized);
			case (true) {
				let balance : Nat = Cycles.balance();

				// TODO: Validate if 100_000_000_000 is the correct amount and if it should be a constant
				let cycles : Nat = balance - 100_000_000_000;

				if (cycles > 0) {
					Cycles.add(cycles);
					await ic.deposit_cycles({ canister_id = _creator });

					return #ok({
						refundedCycles = cycles;
					});
				};

				#ok({
					refundedCycles = 0;
				});
			};
		};
	};

	type GetInfoResponseOk = {
		id : Principal;
		name : Text;
	};

	type GetInfoResponseErr = {
		#unauthorized;
	};

	type GetInfoResponse = Result.Result<GetInfoResponseOk, GetInfoResponseErr>;

	public shared query ({ caller }) func getInfo() : async GetInfoResponse {
		if (not hasAccess(caller)) {
			return #err(#unauthorized);
		};

		let result = {
			id = Principal.fromActor(this);
			name = _name;
		};

		return #ok(result);
	};

	type GetRolesResponseOk = [Role.Role];

	type GetRolesResponseErr = {
		#unauthorized;
	};

	type GetRolesResponse = Result.Result<GetRolesResponseOk, GetRolesResponseErr>;

	public shared query ({ caller }) func getRoles() : async GetRolesResponse {
		if (not hasAccess(caller)) {
			return #err(#unauthorized);
		};

		return #ok(roleService.getAllArray());
	};

	type GetMembersResponseOk = [Member.Member];

	type GetMembersResponseErr = {
		#unauthorized;
	};

	type GetMembersResponse = Result.Result<GetMembersResponseOk, GetMembersResponseErr>;

	public shared query ({ caller }) func getMembers() : async GetMembersResponse {
		if (not hasAccess(caller)) {
			return #err(#unauthorized);
		};

		return #ok(memberService.getAllArray());
	};

	type AddMemberResultOk = ();

	type AddMemberResultErr = {
		#unauthorized;
		#memberAlreadyRegistered;
		#additionalOwnersNotAllowed;
	};

	type AddMemberResult = Result.Result<AddMemberResultOk, AddMemberResultErr>;

	public shared ({ caller }) func addMember(userId : Principal, roleId : Nat) : async AddMemberResult {
		if (not hasAccess(caller)) {
			return #err(#unauthorized);
		};

		if (roleId == Role.DEFAULT_OWNER_ROLE_ID) {
			return #err(#additionalOwnersNotAllowed);
		};

		let result = memberService.add(userId, roleId);

		switch (result) {
			case (#err(#memberAlreadyRegistered)) #err(#memberAlreadyRegistered);
			case (#ok(_)) #ok();
		};
	};

	type RemoveMemberResultOk = ();

	type RemoveMemberResultErr = {
		#unauthorized;
		#memberNotFound;
		#ownersCannotBeRemoved;
	};

	type RemoveMemberResult = Result.Result<RemoveMemberResultOk, RemoveMemberResultErr>;

	public shared ({ caller }) func removeMember(userId : Principal) : async RemoveMemberResult {
		if (not hasAccess(caller)) {
			return #err(#unauthorized);
		};

		return memberService.remove(userId);
	};
};
