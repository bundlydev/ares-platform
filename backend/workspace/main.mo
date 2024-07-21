import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";

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
	let ownerRole = roleService.add({ name = "Owner" });
	// TODO: Improve error handling
	let _a = memberService.add(owner, ownerRole.id);
	// Init End

	private func hasAccess(caller : Principal) : Bool {
		if (Principal.isAnonymous(caller)) return false;

		if (Principal.equal(caller, _creator)) return true;

		return false;
	};

	type GetInfoResponseOk = {
		id : Principal;
		name : Text;
		members : [{
			id : Principal;
			roleId : Nat;
		}];
	};

	type GetInfoResponseErr = {
		#unauthorized;
	};

	type GetInfoResponse = Result.Result<GetInfoResponseOk, GetInfoResponseErr>;

	public shared query ({ caller }) func getInfo() : async GetInfoResponse {
		if (not hasAccess(caller)) {
			return #err(#unauthorized);
		};

		let memberMap = memberService.getAll();
		let memberIter = Map.vals(memberMap);
		let members = Iter.toArray(memberIter);

		let result = {
			id = Principal.fromActor(this);
			name = _name;
			members;
		};

		return #ok(result);
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

		let result = memberService.add(userId, roleId);

		switch (result) {
			case (#err(#memberAlreadyRegistered)) {
				#err(#memberAlreadyRegistered);
			};
			case (#ok(_)) { #ok() };
		};
	};
};
