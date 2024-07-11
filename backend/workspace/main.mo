import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
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

	// Initializer
	let ownerRole = roleService.add({ name = "Owner" });
	memberService.add(owner, ownerRole.id);

	private func hasAccess(principal : Principal, roles : [Nat]) : Bool {
		if (Principal.isAnonymous(principal)) return false;

		if (Array.size(roles) == 0) return true;

		// TODO: verify if principal is in _members and has one of the roles
		return principal == _creator;
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
		if (not hasAccess(caller, [])) {
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

	// TODO: Add member management functions
};
