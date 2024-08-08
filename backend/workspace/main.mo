// Base Modules
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import Cycles "mo:base/ExperimentalCycles";

// Mops Modules
import IC "mo:ic";

// Custom Modules
import MemberModule "./modules/member";
import RoleModule "./modules/role";
import WebhookModule "./modules/webhook";

shared ({ caller = creator }) actor class WorkspaceActorClass(name : Text) = Self {
	// Storage
	private stable let _creator = creator;
	private stable let _name = name;
	private stable let _roles = Map.new<Nat, RoleModule.RoleEntity>();
	private stable let _members = Map.new<Principal, MemberModule.MemberEntity>();
	private stable let _webhooks = Map.new<Principal, WebhookModule.ListenerEntity>();

	// Services
	private let ic = actor ("aaaaa-aa") : IC.Service;
	private let webhookService = WebhookModule.WebhookService(_webhooks);
	private let roleService = RoleModule.RoleService(_roles);
	private let memberService = MemberModule.MemberService(_members, webhookService);

	private func hasAdminAccess(caller : Principal) : Bool {
		if (Principal.isAnonymous(caller)) return false;

		if (memberService.isAdmin(caller)) return true;

		if (memberService.isOwner(caller)) return true;

		if (Principal.equal(caller, _creator)) return true;

		return false;
	};

	type AddFirstOwnerResultOk = ();

	type AddFirstOwnerResultErr = {
		#unauthorized;
	};

	type AddFirstOwnerResult = Result.Result<AddFirstOwnerResultOk, AddFirstOwnerResultErr>;

	public shared ({ caller }) func addFirstOwner(userId : Principal) : async AddFirstOwnerResult {
		if (not Principal.equal(caller, _creator)) {
			return #err(#unauthorized);
		};

		// TODO: Prevent adding if there is already an owner

		ignore memberService.add(userId, RoleModule.DEFAULT_OWNER_ROLE_ID);

		#ok();
	};

	type DeleteResultOk = {
		refundedCycles : Nat;
	};

	type DeleteResultErr = {
		#unauthorized;
	};

	type DeleteResult = Result.Result<DeleteResultOk, DeleteResultErr>;

	public shared ({ caller }) func onDelete(requester : Principal) : async DeleteResult {
		if (not Principal.equal(caller, _creator)) {
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

	type GetInfoResultOk = {
		id : Principal;
		name : Text;
	};

	type GetInfoResultErr = {
		#unauthorized;
	};

	type GetInfoResult = Result.Result<GetInfoResultOk, GetInfoResultErr>;

	public shared query ({ caller }) func getInfo() : async GetInfoResult {
		if (not memberService.isMember(caller)) {
			return #err(#unauthorized);
		};

		let result = {
			id = Principal.fromActor(Self);
			name = _name;
		};

		return #ok(result);
	};

	type GetRolesResultOk = [RoleModule.RoleEntity];

	type GetRolesResultErr = {
		#unauthorized;
	};

	type GetRolesResult = Result.Result<GetRolesResultOk, GetRolesResultErr>;

	public shared query ({ caller }) func getRoles() : async GetRolesResult {
		if (not memberService.isMember(caller)) {
			return #err(#unauthorized);
		};

		return #ok(roleService.getAllArray());
	};

	type GetMembersResultOk = [MemberModule.MemberEntity];

	type GetMembersResultErr = {
		#unauthorized;
	};

	type GetMembersResult = Result.Result<GetMembersResultOk, GetMembersResultErr>;

	public shared query ({ caller }) func getMembers() : async GetMembersResult {
		if (not hasAdminAccess(caller)) {
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
		if (not hasAdminAccess(caller)) {
			return #err(#unauthorized);
		};

		// TODO: Validate if userId has a profile in the backoffice-gateway

		if (roleId == RoleModule.DEFAULT_OWNER_ROLE_ID) {
			return #err(#additionalOwnersNotAllowed);
		};

		let addResult = await memberService.add(userId, roleId);

		switch (addResult) {
			case (#ok()) #ok();
			case (error) error;
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
		if (not hasAdminAccess(caller)) {
			return #err(#unauthorized);
		};

		return await memberService.remove(userId);
	};

	type AddWebhookListenerResultOk = ();

	type AddWebhookListenerResultErr = {
		#unauthorized;
	};

	type AddWebhookListenerResult = Result.Result<AddWebhookListenerResultOk, AddWebhookListenerResultErr>;

	public shared ({ caller }) func addWebhookListener(canisterId : Principal) : async AddWebhookListenerResult {
		if (not hasAdminAccess(caller)) {
			return #err(#unauthorized);
		};

		webhookService.register({ canisterId });

		#ok();
	};
};
