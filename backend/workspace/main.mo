// Base Modules
import Map "mo:map/Map";
import Set "mo:map/Set";
import Principal "mo:base/Principal";
import Cycles "mo:base/ExperimentalCycles";
import Array "mo:base/Array";

// Mops Modules
import IC "mo:ic";

// Custom Modules
import Access "mo:access-management/Access";
import PermissionsManagement "mo:access-management/Permissions";
import RolesManagement "mo:access-management/Roles";
import AccessManagement "mo:access-management/Access";

import WorkspaceOrchestratorTypes "../workspace-orchestrator/types";

// IAM Imports
import IamTypes "./modules/iam/types";
import IamPermissions "./modules/iam/permissions";
import IamPolicy "./modules/iam/policy";
import IamRole "./modules/iam/role";
import IamAccess "./modules/iam/access";
import IamEvents "./modules/iam/events";

// Users Imports
import UserPermission "./modules/users/permissions";

// Webhooks Imports
import WebhooksModels "./modules/webhooks/models";
import WebhookService "./modules/webhooks/service";
import WebhookPermissions "./modules/webhooks/permissions";

// General Imports
import Types "./types";
import IamResults "./results/iam-results";
import UsersResults "./results/users-results";
import WebhooksResults "./results/webhooks-results";

shared ({ caller = creator }) actor class WorkspaceClass(owner : Principal) {
	private stable let _creator = creator;
	private stable let _owner = owner;

	private let ic = actor ("aaaaa-aa") : IC.Service;

	// Iam Config
	private var _iamPolicies : IamPolicy.PolicyCollection = Map.new();
	private let _iamRoles : IamRole.RoleCollection = Map.new();
	private let _iamAccessList : IamAccess.AccessCollection = Map.new();
	private let policyService = IamPolicy.PolicyService(_iamPolicies);
	private let roleService = IamRole.RoleService(_iamRoles, policyService);
	private let accessService = IamAccess.AccessService(_iamAccessList, policyService, roleService);

	// Users Config
	private var _userPermissions : PermissionsManagement.PermissionsRepository = Set.new();
	private var _userRoles : RolesManagement.RolesRepository = Map.new();
	private var _userAccessList : AccessManagement.AccessRepository = Map.new();
	private let userPermissionsService = PermissionsManagement.PermissionsService(_userPermissions);
	private let userRolesService = RolesManagement.RolesService(_userRoles, userPermissionsService);
	private let userAccessService = AccessManagement.AccessService(_userAccessList, userRolesService, userPermissionsService);

	// Webhooks Config
	private stable var _webhooks : WebhooksModels.WebhookRepository = Map.new();
	private let webhookService = WebhookService.WebhookService(_webhooks);

	// Init
	public shared ({ caller }) func init() : async () {
		if (not Principal.equal(_creator, caller)) {
			return;
		};

		let adminPolicy = {
			pid = "AdministratorAccess";
			ptype = #managed;
			statements = [{
				effect = #allow;
				action = #all;
			}];
		};

		await policyService.create(adminPolicy);

		let adminRoleData = {
			name = "Administrator";
			description = "Grant full access to the workspace";
			policies = [adminPolicy.pid];
		};

		let role = await roleService.create(adminRoleData);

		let newAccess = {
			identity = _owner;
			roleId = role.rid;
			itype = #user;
		};

		ignore await accessService.create(newAccess);

		return ();
	};

	public shared ({ caller }) func prepare_deletion() : async WorkspaceOrchestratorTypes.PrepareCanisterDeletionResult {
		if (not Principal.equal(caller, _creator)) {
			return #err(#unauthorized);
		};

		let balance : Nat = Cycles.balance();

		// TODO: Validate if 100_000_000_000 is the correct amount and if it should be a constant
		let cycles : Nat = balance - 100_000_000_000;

		if (cycles > 0) {
			Cycles.add<system>(cycles);
			await ic.deposit_cycles({ canister_id = _creator });

			return #ok({
				refundedCycles = cycles;
			});
		};

		#ok({
			refundedCycles = 0;
		});
	};

	/*
   * IAM Methods
   */

	private func iam_identity_has_access(identity : Principal, access : IamTypes.AccessType) : Bool {
		return accessService.hasPermission(identity, access);
	};

	public shared query ({ caller }) func iam_get_permission_list() : async IamResults.GetIamActionsResult {
		if (not iam_identity_has_access(caller, #permission(IamPermissions.PERMISSION_LIST.GET_PERMISSION_LIST.id))) return #err(#unauthorized);

		return #ok(IamPermissions.PERMISSION_LIST);
	};

	public shared query ({ caller }) func iam_get_policies() : async IamResults.GetPermissionsResult {
		if (not iam_identity_has_access(caller, #permission(IamPermissions.PERMISSION_LIST.GET_POLICIES.id))) return #err(#unauthorized);

		return #ok(policyService.getAll());
	};

	public shared ({ caller }) func iam_create_policy(data : Types.CreatePolicyData) : async IamResults.CreatePermissionResult {
		if (not iam_identity_has_access(caller, #permission(IamPermissions.PERMISSION_LIST.CREATE_POLICY.id))) return #err(#unauthorized);

		try {
			await policyService.create(data);

			let event : IamEvents.PolicyCreatedEvent = {
				action = "iam.role.created";
				payload = data;
			};

			ignore webhookService.emit(event);
			return #ok();
		} catch (_error) {
			return #err(#permissionAlreadyAdded);
		};
	};

	public shared query ({ caller }) func iam_get_roles() : async IamResults.GetRolesResult {
		if (not iam_identity_has_access(caller, #permission(IamPermissions.PERMISSION_LIST.GET_ROLES.id))) return #err(#unauthorized);

		return #ok(roleService.getAll());
	};

	public shared ({ caller }) func iam_create_role(data : Types.CreateRoleData) : async IamResults.AddRoleResult {
		if (not iam_identity_has_access(caller, #permission(IamPermissions.PERMISSION_LIST.CREATE_ROLE.id))) return #err(#unauthorized);

		try {
			let role = await roleService.create(data);

			return #ok(role);
		} catch (_error) {
			// TODO: Catch other errors
			return #err(#roleAlreadyAdded);
		};
	};

	public shared ({ caller }) func iam_delete_role(roleId : Text, newRoleId : Text) : async IamResults.RemoveRoleResult {
		if (not iam_identity_has_access(caller, #permission(IamPermissions.PERMISSION_LIST.DELETE_ROLE.id))) return #err(#unauthorized);

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

	public shared ({ caller }) func iam_add_policy_to_role(roleName : Text, policyId : Text) : async IamResults.AddPermissionToRoleResult {
		if (not iam_identity_has_access(caller, #permission(IamPermissions.PERMISSION_LIST.ADD_POLICY_TO_ROLE.id))) return #err(#unauthorized);

		try {
			// TODO: Validate if policy exists
			ignore roleService.addPolicy(roleName, policyId);
			return #ok();
		} catch (_error) {
			// TODO: Catch other errors
			return #err(#roleNotFound);
		};
	};

	public shared ({ caller }) func iam_remove_policy_from_role(roleName : Text, policyId : Text) : async IamResults.RemovePermissionFromRoleResult {
		if (not iam_identity_has_access(caller, #permission(IamPermissions.PERMISSION_LIST.REMOVE_POLICY_FROM_ROLE.id))) return #err(#unauthorized);

		try {
			ignore roleService.removePolicy(roleName, policyId);
			return #ok();
		} catch (_error) {
			// TODO: Catch other errors
			return #err(#roleNotFound);
		};
	};

	public shared query ({ caller }) func iam_get_access_list(options : Types.GetAccessListOptions) : async IamResults.GetAccessListResult {
		if (not iam_identity_has_access(caller, #permission(IamPermissions.PERMISSION_LIST.GET_ACCESS_LIST.id))) return #err(#unauthorized);

		var accessList = accessService.getAll();

		// TODO: Move this filter into the AccessService
		switch (options.filters.itype) {
			case (#user) {
				accessList := Array.filter<IamAccess.Access>(accessList, func(access) = access.itype == #user);
			};
			case (#app) {
				accessList := Array.filter<IamAccess.Access>(accessList, func(access) = access.itype == #app);
			};
			case (#orchestrator) {
				accessList := Array.filter<IamAccess.Access>(accessList, func(access) = access.itype == #orchestrator);
			};
			case (#all) {};
		};

		return #ok(accessList);
	};

	public shared ({ caller }) func iam_create_access(data : Types.CreateAccessData) : async IamResults.CreateAccessResult {
		if (not iam_identity_has_access(caller, #permission(IamPermissions.PERMISSION_LIST.CREATE_ACCESS.id))) return #err(#unauthorized);

		try {
			let access = await accessService.create(data);
			let orchestrator = actor (Principal.toText(_creator)) : actor {
				add_workspace_member : shared Principal -> async ();
			};

			await orchestrator.add_workspace_member(data.identity);

			return #ok(access);
		} catch (_error) {
			// TODO: Catch other errors
			return #err(#accessAlreadyExists);
		};

	};

	public shared ({ caller }) func iam_delete_access(identity : Principal) : async IamResults.RemoveAccessResult {
		if (not iam_identity_has_access(caller, #permission(IamPermissions.PERMISSION_LIST.DELETE_ACCESS.id))) return #err(#unauthorized);

		try {
			let access = await accessService.delete(identity);

			let orchestrator = actor (Principal.toText(_creator)) : actor {
				remove_workspace_member : shared Principal -> async ();
			};

			await orchestrator.remove_workspace_member(identity);

			#ok(access);
		} catch (_error) {
			return #err(#accessDoesNotExist);
		};
	};

	public shared ({ caller }) func iam_change_access_role(identity : Principal, roleId : Text) : async IamResults.AssignRoleToPrincipalResult {
		if (not iam_identity_has_access(caller, #permission(IamPermissions.PERMISSION_LIST.CHANGE_ACCESS_ROLE.id))) return #err(#unauthorized);

		try {
			ignore accessService.changeRole(identity, roleId);
			return #ok();
		} catch (_error) {
			// TODO: Catch other errors
			return #err(#roleAlreadyAssigned);
		};
	};

	/*
   * Users Methods
   */

	public shared query ({ caller }) func users_has_access(identity : Principal, permission : Text) : async UsersResults.HasAccessResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.VERIFY_ACCESS.id))) return #err(#unauthorized);

		return #ok(userAccessService.hasPermission(identity, permission));
	};

	public shared query ({ caller }) func users_get_permissions() : async UsersResults.GetPermissionsResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.GET_PERMISSIONS.id))) return #err(#unauthorized);

		return #ok(userPermissionsService.getAll());
	};

	public shared ({ caller }) func users_create_permission(permission : UsersResults.CreatePermissionData) : async UsersResults.CreatePermissionResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.CREATE_PERMISSION.id))) return #err(#unauthorized);

		switch (userPermissionsService.create({ permission with createdBy = caller })) {
			case (#ok(permission)) {
				// TODO: Emit event

				#ok(permission);
			};
			case (#err(error)) #err(error);
		};
	};

	public shared ({ caller }) func users_delete_permission(permissionId : Text) : async UsersResults.DeletePermissionResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.DELETE_PERMISSION.id))) return #err(#unauthorized);

		if (not userPermissionsService.exists(permissionId)) return #err(#permissionDoesNotExist);

		switch (userPermissionsService.delete(permissionId)) {
			case (true) {
				let roles = userRolesService.getAll();

				for (role in roles.vals()) {
					ignore userRolesService.removePermission(role.name, permissionId);
				};

				let accesses = accessService.getAll();

				for (access in accesses.vals()) {
					ignore userAccessService.removePermission(access.identity, permissionId);
				};

				// TODO: Emit event

				#ok();
			};
			case (false) #ok();
		};
	};

	public shared query ({ caller }) func users_get_roles() : async UsersResults.GetRolesResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.GET_ROLES.id))) return #err(#unauthorized);

		return #ok(userRolesService.getAll());
	};

	public shared ({ caller }) func users_create_role(role : UsersResults.CreateRoleData) : async UsersResults.CreateRoleResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.CREATE_ROLE.id))) return #err(#unauthorized);

		switch (userRolesService.create({ role with createdBy = caller })) {
			case (#ok(role)) {
				// TODO: Emit event

				return #ok(role);
			};
			case (#err(error)) #err(error);
		};
	};

	public shared ({ caller }) func users_delete_role(roleId : Text) : async UsersResults.DeleteRoleResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.DELETE_ROLE.id))) return #err(#unauthorized);

		switch (userRolesService.delete(roleId)) {
			case (true) {
				let accesses = accessService.getAll();

				for (access in accesses.vals()) {
					ignore userAccessService.removeRole(access.identity, roleId);
				};

				// TODO: Emit event

				return #ok();
			};
			case (false) return #ok();
		};
	};

	public shared ({ caller }) func users_add_permission_to_role(roleId : Text, permissionId : Text) : async UsersResults.AddPermissionToRoleResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.ADD_PERMISSION_TO_ROLE.id))) return #err(#unauthorized);

		switch (userRolesService.addPermission(roleId, permissionId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	public shared ({ caller }) func users_remove_permission_from_role(roleId : Text, permissionId : Text) : async UsersResults.RemovePermissionFromRoleResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.REMOVE_PERMISSION_FROM_ROLE.id))) return #err(#unauthorized);

		switch (userRolesService.removePermission(roleId, permissionId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	public shared query ({ caller }) func users_get_access_list() : async UsersResults.GetAccessListResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.GET_ACCESS_LIST.id))) return #err(#unauthorized);

		return #ok(userAccessService.getAll());
	};

	public shared ({ caller }) func users_create_access(data : UsersResults.CreateAccessData) : async UsersResults.CreateAccessResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.CREATE_ACCESS.id))) return #err(#unauthorized);

		switch (userAccessService.create({ data with createdBy = caller })) {
			case (#ok(access)) {

				#ok(access);
			};
			case (#err(error)) #err(error);
		};
	};

	public shared ({ caller }) func users_delete_access(accessId : Principal) : async UsersResults.DeleteAccessResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.DELETE_ACCESS.id))) return #err(#unauthorized);

		switch (userAccessService.delete(accessId)) {
			case (true) {
				// TODO: Emit event

				#ok();
			};
			case (false) return #ok();
		};
	};

	public shared ({ caller }) func users_change_access_status(accessId : Principal, status : Access.AccessStatus) : async UsersResults.GetAccessResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.CHANGE_ACCESS_STATUS.id))) return #err(#unauthorized);

		return userAccessService.changeStatus(accessId, status);
	};

	public shared ({ caller }) func users_add_role_to_access(accessId : Principal, roleId : Text) : async UsersResults.AddRoleToAccessResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.ADD_ROLE_TO_ACCESS.id))) return #err(#unauthorized);

		switch (userAccessService.addRole(accessId, roleId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	public shared ({ caller }) func users_remove_role_from_access(accessId : Principal, roleId : Text) : async UsersResults.RemoveRoleFromAccessResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.REMOVE_ROLE_FROM_ACCESS.id))) return #err(#unauthorized);

		switch (userAccessService.removeRole(accessId, roleId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	public shared ({ caller }) func users_add_permission_to_access(accessId : Principal, permissionId : Text) : async UsersResults.AddPermissionToAccessResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.ADD_PERMISSION_TO_ACCESS.id))) return #err(#unauthorized);

		switch (userAccessService.addPermission(accessId, permissionId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	public shared ({ caller }) func users_remove_permission_from_access(accessId : Principal, permissionId : Text) : async UsersResults.RemovePermissionFromAccessResult {
		if (not iam_identity_has_access(caller, #permission(UserPermission.PERMISSION_LIST.REMOVE_PERMISSION_FROM_ACCESS.id))) return #err(#unauthorized);

		switch (userAccessService.removePermission(accessId, permissionId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	/*
   * Webhooks Methods
   */

	public shared composite query ({ caller }) func webhooks_get_webhook_list() : async WebhooksResults.GetWebhookListResult {
		if (not iam_identity_has_access(caller, #permission(WebhookPermissions.PERMISSION_LIST.GET_WEBHOOK_LIST.id))) return #err(#unauthorized);

		return #ok(webhookService.getAll());
	};

	public shared ({ caller }) func webhooks_register_webhook(data : Types.RegisterWebhookData) : async WebhooksResults.RegisterWebhookResult {
		if (not iam_identity_has_access(caller, #permission(WebhookPermissions.PERMISSION_LIST.REGISTER_WEBHOOK.id))) return #err(#unauthorized);

		webhookService.register(data.principal, data.name, caller);

		return #ok();
	};

	public shared ({ caller }) func webhooks_remove_webhook(principal : Principal) : async WebhooksResults.RegisterWebhookResult {
		if (not iam_identity_has_access(caller, #permission(WebhookPermissions.PERMISSION_LIST.REMOVE_WEBHOOK.id))) return #err(#unauthorized);

		webhookService.remove(principal);

		return #ok();
	};
};
