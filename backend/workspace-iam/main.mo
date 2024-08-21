// Base Modules
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Cycles "mo:base/ExperimentalCycles";
import Array "mo:base/Array";

// Mops Modules
import IC "mo:ic";
import Map "mo:map/Map";

// Custom Modules
import PolicyActionModule "./modules/policy-action";
import PolicyModule "./modules/policy";
import RoleModule "./modules/role";
import AccessModule "./modules/access";

import WorkspaceIamEventsModule "./events";

// Actors
import AccountManager "../account-manager/main";

shared ({ caller = creator }) actor class IamActorClass(owner : Principal, accountManager : Principal) = Self {
	let POLICY_ACTIONS = PolicyActionModule.POLICY_ACTIONS;

	private stable let _creator = actor (Principal.toText(creator)) : actor {
		event_listener : (data : WorkspaceIamEventsModule.EventVariants) -> ();
	};

	// Canisters
	private stable let _accountManager = actor (Principal.toText(accountManager)) : AccountManager.AccountManager;

	private stable let _owner = owner;

	// Storage
	var _policies : PolicyModule.PolicyCollection = Map.new();
	let _roles : RoleModule.RoleCollection = Map.new();
	let _accessList : AccessModule.AccessCollection = Map.new();

	// Services
	private let ic = actor ("aaaaa-aa") : IC.Service;
	private let policyService = PolicyModule.PolicyService(_policies);
	private let roleService = RoleModule.RoleService(_roles, policyService);
	private let accessService = AccessModule.AccessService(_accessList, policyService, roleService);

	type DeleteResultOk = {
		refundedCycles : Nat;
	};

	type DeleteResultErr = {
		#unauthorized;
	};

	type DeleteResult = Result.Result<DeleteResultOk, DeleteResultErr>;

	public shared ({ caller }) func prepare_deletion() : async DeleteResult {
		if (not Principal.equal(caller, Principal.fromActor(_creator))) {
			return #err(#unauthorized);
		};

		let balance : Nat = Cycles.balance();

		// TODO: Validate if 100_000_000_000 is the correct amount and if it should be a constant
		let cycles : Nat = balance - 100_000_000_000;

		if (cycles > 0) {
			Cycles.add<system>(cycles);
			await ic.deposit_cycles({ canister_id = Principal.fromActor(_creator) });

			return #ok({
				refundedCycles = cycles;
			});
		};

		#ok({
			refundedCycles = 0;
		});
	};

	type GetIamActionsResultOk = PolicyActionModule.PolicyActions;

	type GetIamActionsResultErr = {
		#unauthorized;
	};

	type GetIamActionsResult = Result.Result<GetIamActionsResultOk, GetIamActionsResultErr>;

	public shared composite query ({ caller }) func get_policy_actions() : async GetIamActionsResult {
		let hasAccess = await has_access(caller, { allowIncognito = false; isPublic = false; action = ?POLICY_ACTIONS.POLICY_READ.action });
		if (not hasAccess) return #err(#unauthorized);

		return #ok(POLICY_ACTIONS);
	};

	type GetPermissionsResultOk = [PolicyModule.Policy];

	type GetPermissionsResultErr = {
		#unauthorized;
	};

	type GetPermissionsResult = Result.Result<GetPermissionsResultOk, GetPermissionsResultErr>;

	public shared composite query ({ caller }) func get_policies() : async GetPermissionsResult {
		let hasAccess = await has_access(caller, { allowIncognito = false; isPublic = false; action = ?POLICY_ACTIONS.POLICY_READ.action });
		if (not hasAccess) return #err(#unauthorized);

		return #ok(policyService.getAll());
	};

	type AddPermissionResultOk = ();

	type AddPermissionResultErr = {
		#unauthorized;
		#permissionAlreadyAdded;
	};

	type AddPermissionResult = Result.Result<AddPermissionResultOk, AddPermissionResultErr>;

	public shared ({ caller }) func create_policy(newPolicy : PolicyModule.Policy) : async AddPermissionResult {
		let hasAccess = await has_access(caller, { allowIncognito = false; isPublic = false; action = ?POLICY_ACTIONS.POLICY_WRITTE.action });
		if (not hasAccess) return #err(#unauthorized);

		try {
			await policyService.add(newPolicy);
			return #ok();
		} catch (_error) {
			return #err(#permissionAlreadyAdded);
		};
	};

	type GetRolesResultOk = [RoleModule.Role];

	type GetRolesResultErr = {
		#unauthorized;
	};

	type GetRolesResult = Result.Result<GetRolesResultOk, GetRolesResultErr>;

	public shared composite query ({ caller }) func get_roles() : async GetRolesResult {
		let hasAccess = await has_access(caller, { allowIncognito = false; isPublic = false; action = ?POLICY_ACTIONS.ROLE_READ.action });
		if (not hasAccess) return #err(#unauthorized);

		return #ok(roleService.getAll());
	};

	type AddRoleResultOk = RoleModule.Role;

	type AddRoleResultErr = {
		#unauthorized;
		#roleAlreadyAdded;
	};

	type AddRoleResult = Result.Result<AddRoleResultOk, AddRoleResultErr>;

	public shared ({ caller }) func create_role(displayName : Text, policies : [Text]) : async AddRoleResult {
		let hasAccess = await has_access(caller, { allowIncognito = false; isPublic = false; action = ?POLICY_ACTIONS.ROLE_WRITTE.action });
		if (not hasAccess) return #err(#unauthorized);

		try {
			let role = await roleService.add({ displayName; policies });
			return #ok(role);
		} catch (_error) {
			return #err(#roleAlreadyAdded);
		};
	};

	type RemoveRoleResultOk = ();

	type RemoveRoleResultErr = {
		#unauthorized;
		#roleNotFound;
	};

	type RemoveRoleResult = Result.Result<RemoveRoleResultOk, RemoveRoleResultErr>;

	public shared ({ caller }) func delete_role(roleId : Text, newRoleId : Text) : async RemoveRoleResult {
		let hasAccess = await has_access(caller, { allowIncognito = false; isPublic = false; action = ?POLICY_ACTIONS.ROLE_WRITTE.action });
		if (not hasAccess) return #err(#unauthorized);

		try {
			// TODO: Validate if role and newRole exist
			ignore await roleService.remove(roleId);

			let accessList = accessService.getAll();

			for (access in accessList.vals()) {
				ignore accessService.changeRole(access.identity, newRoleId);
			};

			return #ok();
		} catch (_error) {
			return #err(#roleNotFound);
		};
	};

	type AddPermissionToRoleResultOk = ();

	type AddPermissionToRoleResultErr = {
		#unauthorized;
		#roleNotFound;
		#permissionAlreadyGranted;
	};

	type AddPermissionToRoleResult = Result.Result<AddPermissionToRoleResultOk, AddPermissionToRoleResultErr>;

	public shared ({ caller }) func add_policy_to_role(roleName : Text, policyId : Text) : async AddPermissionToRoleResult {
		let hasAccess = await has_access(caller, { allowIncognito = false; isPublic = false; action = ?POLICY_ACTIONS.ROLE_WRITTE.action });
		if (not hasAccess) return #err(#unauthorized);

		try {
			// TODO: Validate if policy exists
			ignore roleService.addPolicy(roleName, policyId);
			return #ok();
		} catch (_error) {
			// TODO: Catch other errors
			return #err(#roleNotFound);
		};
	};

	type RemovePermissionFromRoleResultOk = ();

	type RemovePermissionFromRoleResultErr = {
		#unauthorized;
		#permissionNotPreviouslyAssigned;
		#roleNotFound;
	};

	type RemovePermissionFromRoleResult = Result.Result<RemovePermissionFromRoleResultOk, RemovePermissionFromRoleResultErr>;

	public shared ({ caller }) func remove_policy_from_role(roleName : Text, policyId : Text) : async RemovePermissionFromRoleResult {
		let hasAccess = await has_access(caller, { allowIncognito = false; isPublic = false; action = ?POLICY_ACTIONS.ROLE_WRITTE.action });
		if (not hasAccess) return #err(#unauthorized);

		try {
			ignore roleService.removePolicy(roleName, policyId);
			return #ok();
		} catch (_error) {
			// TODO: Catch other errors
			return #err(#roleNotFound);
		};
	};

	type GetAccessListResultOk = [AccessModule.Access];

	type GetAccessListResultErr = {
		#unauthorized;
	};

	type GetAccessListResult = Result.Result<GetAccessListResultOk, GetAccessListResultErr>;

	type GetAccessListOptions = {
		// TODO: Maket it optional
		filters : {
			// TODO: Maket it optional
			itype : AccessModule.AccessIdentityType or { #all };
		};
	};

	public shared composite query ({ caller }) func get_access_list(options : GetAccessListOptions) : async GetAccessListResult {
		let hasAccess = await has_access(caller, { allowIncognito = false; isPublic = false; action = ?POLICY_ACTIONS.ACCESS_READ.action });
		if (not hasAccess) return #err(#unauthorized);

		var accessList = accessService.getAll();

		switch (options.filters.itype) {
			case (#user) {
				accessList := Array.filter<AccessModule.Access>(accessList, func(access) = access.itype == #user);
			};
			case (#app) {
				accessList := Array.filter<AccessModule.Access>(accessList, func(access) = access.itype == #app);
			};
			case (#orchestrator) {
				accessList := Array.filter<AccessModule.Access>(accessList, func(access) = access.itype == #orchestrator);
			};
			case (#all) {};
		};

		return #ok(accessList);
	};

	type AddAccessResultOk = AccessModule.Access;

	type AddAccessResultErr = {
		#unauthorized;
		#accessAlreadyExists;
	};

	type AddAccessResult = Result.Result<AddAccessResultOk, AddAccessResultErr>;

	public shared ({ caller }) func create_access(identity : Principal, roleId : Text, itype : AccessModule.AccessIdentityType) : async AddAccessResult {
		let hasAccess = await has_access(caller, { allowIncognito = false; isPublic = false; action = ?POLICY_ACTIONS.ACCESS_WRITTE.action });
		if (not hasAccess) return #err(#unauthorized);

		try {
			let access = await accessService.add(identity, roleId, itype);
			let newEvent : WorkspaceIamEventsModule.EventVariants = #workspaceAccessCreated(access);

			_creator.event_listener(newEvent);
			return #ok(access);
		} catch (_error) {
			// TODO: Catch other errors
			return #err(#accessAlreadyExists);
		};

	};

	type RemoveAccessResultOk = AccessModule.Access;

	type RemoveAccessResultErr = {
		#unauthorized;
		#accessDoesNotExist;
	};

	type RemoveAccessResult = Result.Result<RemoveAccessResultOk, RemoveAccessResultErr>;

	public shared ({ caller }) func delete_access(identity : Principal) : async RemoveAccessResult {
		let hasAccess = await has_access(caller, { allowIncognito = false; isPublic = false; action = ?POLICY_ACTIONS.ACCESS_WRITTE.action });
		if (not hasAccess) return #err(#unauthorized);

		try {
			let access = await accessService.remove(identity);
			let newEvent : WorkspaceIamEventsModule.EventVariants = #workspaceAccessRemoved(access);

			_creator.event_listener(newEvent);
			#ok(access);
		} catch (_error) {
			return #err(#accessDoesNotExist);
		};
	};

	type AssignRoleToPrincipalResultOk = ();

	type AssignRoleToPrincipalResultErr = {
		#unauthorized;
		#roleAlreadyAssigned;
		#roleNotFound;
	};

	type AssignRoleToPrincipalResult = Result.Result<AssignRoleToPrincipalResultOk, AssignRoleToPrincipalResultErr>;

	public shared ({ caller }) func change_access_role(identity : Principal, roleId : Text) : async AssignRoleToPrincipalResult {
		let hasAccess = await has_access(caller, { allowIncognito = false; isPublic = false; action = ?POLICY_ACTIONS.ACCESS_WRITTE.action });
		if (not hasAccess) return #err(#unauthorized);

		try {
			ignore accessService.changeRole(identity, roleId);
			return #ok();
		} catch (_error) {
			// TODO: Catch other errors
			return #err(#roleAlreadyAssigned);
		};
	};

	type ValidateAccessOptions = {
		allowIncognito : Bool;
		isPublic : Bool;
		action : ?Text;
	};

	public shared query func has_access(identity : Principal, options : ValidateAccessOptions) : async Bool {
		if (options.isPublic) return true;

		if (not options.isPublic and Principal.isAnonymous(identity)) return false;

		if (Principal.equal(identity, Principal.fromActor(_creator))) return true;

		// TODO: Remove this validation?
		if (not options.allowIncognito and Principal.isAnonymous(identity)) return false;

		switch (options.action) {
			case (?action) {
				return accessService.hasPermission(identity, action);
			};
			case null {
				return false;
			};
		};
	};
};
