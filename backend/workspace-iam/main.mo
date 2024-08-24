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
import AccessPermissionModule "./modules/access-permission";
import PolicyModule "./modules/policy";
import RoleModule "./modules/role";
import AccessModule "./modules/access";

import WorkspaceIamEventsModule "./events";

shared ({ caller = creator }) actor class IamActorClass(owner : Principal) = Self {
	let ACCESS_PERMISSION_LIST = AccessPermissionModule.ACCESS_PERMISSION_LIST;

	private stable let _creator = actor (Principal.toText(creator)) : actor {
		event_listener : (data : WorkspaceIamEventsModule.EventVariants) -> ();
	};

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

	type AccessType = {
		// TODO: Implement public access
		// #public;
		#authenticated;
		#permission : Text;
	};

	private func identity_has_access(identity : Principal, access : AccessType) : Bool {
		if (Principal.equal(identity, Principal.fromActor(_creator))) return true;

		switch (access) {
			// TODO: Implement public access
			// case (#public) return true;
			case (#authenticated) return not Principal.isAnonymous(identity);
			case (#permission(permission)) {
				return accessService.hasPermission(identity, permission);
			};
		};
	};

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

	type GetIamActionsResultOk = AccessPermissionModule.AccessPermissionList;

	type GetIamActionsResultErr = {
		#unauthorized;
	};

	type GetIamActionsResult = Result.Result<GetIamActionsResultOk, GetIamActionsResultErr>;

	public shared composite query ({ caller }) func get_access_permission_list() : async GetIamActionsResult {
		if (not identity_has_access(caller, #permission(ACCESS_PERMISSION_LIST.GET_ACCESS_PERMISSION_LIST.id))) return #err(#unauthorized);

		return #ok(ACCESS_PERMISSION_LIST);
	};

	type GetPermissionsResultOk = [PolicyModule.Policy];

	type GetPermissionsResultErr = {
		#unauthorized;
	};

	type GetPermissionsResult = Result.Result<GetPermissionsResultOk, GetPermissionsResultErr>;

	public shared composite query ({ caller }) func get_policies() : async GetPermissionsResult {
		if (not identity_has_access(caller, #permission(ACCESS_PERMISSION_LIST.GET_POLICIES.id))) return #err(#unauthorized);

		return #ok(policyService.getAll());
	};

	type AddPermissionResultOk = ();

	type AddPermissionResultErr = {
		#unauthorized;
		#permissionAlreadyAdded;
	};

	type AddPermissionResult = Result.Result<AddPermissionResultOk, AddPermissionResultErr>;

	public shared ({ caller }) func create_policy(newPolicy : PolicyModule.Policy) : async AddPermissionResult {
		if (not identity_has_access(caller, #permission(ACCESS_PERMISSION_LIST.CREATE_POLICY.id))) return #err(#unauthorized);

		try {
			await policyService.create(newPolicy);
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
		if (not identity_has_access(caller, #permission(ACCESS_PERMISSION_LIST.GET_ROLES.id))) return #err(#unauthorized);

		return #ok(roleService.getAll());
	};

	type CreateRoleData = {
		name : Text;
		description : Text;
		policies : [Text];
	};

	type AddRoleResultOk = RoleModule.Role;

	type AddRoleResultErr = {
		#unauthorized;
		#roleAlreadyAdded;
	};

	type AddRoleResult = Result.Result<AddRoleResultOk, AddRoleResultErr>;

	public shared ({ caller }) func create_role(data : CreateRoleData) : async AddRoleResult {
		if (not identity_has_access(caller, #permission(ACCESS_PERMISSION_LIST.CREATE_ROLE.id))) return #err(#unauthorized);

		try {
			let role = await roleService.create(data);
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
		if (not identity_has_access(caller, #permission(ACCESS_PERMISSION_LIST.DELETE_ROLE.id))) return #err(#unauthorized);

		try {
			// TODO: Validate if role and newRole exist
			ignore await roleService.delete(roleId);

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
		if (not identity_has_access(caller, #permission(ACCESS_PERMISSION_LIST.ADD_POLICY_TO_ROLE.id))) return #err(#unauthorized);

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
		if (not identity_has_access(caller, #permission(ACCESS_PERMISSION_LIST.REMOVE_POLICY_FROM_ROLE.id))) return #err(#unauthorized);

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
		if (not identity_has_access(caller, #permission(ACCESS_PERMISSION_LIST.GET_ACCESS_LIST.id))) return #err(#unauthorized);

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
		if (not identity_has_access(caller, #permission(ACCESS_PERMISSION_LIST.CREATE_ACCESS.id))) return #err(#unauthorized);

		try {
			let access = await accessService.create(identity, roleId, itype);
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
		if (not identity_has_access(caller, #permission(ACCESS_PERMISSION_LIST.DELETE_ACCESS.id))) return #err(#unauthorized);

		try {
			let access = await accessService.delete(identity);
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
		if (not identity_has_access(caller, #permission(ACCESS_PERMISSION_LIST.CHANGE_ACCESS_ROLE.id))) return #err(#unauthorized);

		try {
			ignore accessService.changeRole(identity, roleId);
			return #ok();
		} catch (_error) {
			// TODO: Catch other errors
			return #err(#roleAlreadyAssigned);
		};
	};

	public shared query func has_access(identity : Principal, access : AccessType) : async Bool {
		return identity_has_access(identity, access);
	};
};
