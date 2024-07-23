import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Map "mo:map/Map";
import Principal "mo:base/Principal";

import Member "./member";
import Role "./role";

shared ({ caller = creator }) actor class WorkspaceClass(name : Text, owner : Principal) = this {
	// Database
	private stable let _creator : Principal = creator;
	private stable var _name : Text = name;
	private stable let _roles = Map.new<Nat, Role.Role>();
	private stable let _members = Map.new<Principal, Member.Member>();

	// Services
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
	};

	type AddMemberResult = Result.Result<AddMemberResultOk, AddMemberResultErr>;

	public shared ({ caller }) func addMember(userId : Principal, roleId : Nat) : async AddMemberResult {
		if (not hasAccess(caller)) {
			return #err(#unauthorized);
		};

		// TODO: Prevent adding members with owner role

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
