// Base Modules
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Cycles "mo:base/ExperimentalCycles";

// Mops Modules
import IC "mo:ic";
import Map "mo:map/Map";
import Set "mo:map/Set";

// Workspace Iam Modules
import WorkspaceIam "../workspace-iam/main";

import Permissions "mo:access-management/Permissions";
import Roles "mo:access-management/Roles";
import Access "mo:access-management/Access";

import AccessPermissionModule "./modules/access-permission";

shared ({ caller = creator }) actor class WorkspaceUserManagementActorClass(owner : Principal, iam : Principal) = Self {
	let ACCESS_PERMISSION_LIST = AccessPermissionModule.ACCESS_PERMISSION_LIST;

	private stable let _creator = creator;
	private stable let _owner = owner;
	private stable let _iam = actor (Principal.toText(iam)) : WorkspaceIam.IamActorClass;

	// Storage
	stable var _permissions : Permissions.PermissionsRepository = Set.new();
	stable var _roles : Roles.RolesRepository = Map.new();
	stable var _accessList : Access.AccessRepository = Map.new();

	// Services
	private let ic = actor ("aaaaa-aa") : IC.Service;
	private let permissionsService = Permissions.PermissionsService(_permissions);
	private let rolesService = Roles.RolesService(_roles, permissionsService);
	private let accessService = Access.AccessService(_accessList, rolesService, permissionsService);

	type PrepareDeletionOk = {
		refundedCycles : Nat;
	};

	type PrepareDeletionErr = {
		#unauthorized;
	};

	type PrepareDeletionResult = Result.Result<PrepareDeletionOk, PrepareDeletionErr>;

	public shared ({ caller }) func prepare_deletion() : async PrepareDeletionResult {
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

	type HasAccessResultOk = Bool;

	type HasAccessResultErr = {
		#unauthorized;
	};

	type HasAccessResult = Result.Result<HasAccessResultOk, HasAccessResultErr>;

	public shared composite query ({ caller }) func has_access(identity : Principal, permission : Text) : async HasAccessResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.VERIFY_ACCESS.id)))) return #err(#unauthorized);

		return #ok(accessService.hasPermission(identity, permission));
	};

	type GetPermissionsResultOk = [Permissions.Permission];

	type GetPermissionsResultErr = {
		#unauthorized;
	};

	type GetPermissionsResult = Result.Result<GetPermissionsResultOk, GetPermissionsResultErr>;

	public shared composite query ({ caller }) func get_permissions() : async GetPermissionsResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.GET_PERMISSIONS.id)))) return #err(#unauthorized);

		return #ok(permissionsService.getAll());
	};

	type CreatePermissionData = {
		action : Text;
		description : Text;
	};

	type CreatePermissionResultOk = Permissions.Permission;

	type CreatePermissionResultErr = {
		#unauthorized;
		#actionAlreadyRegistered;
	};

	type CreatePermissionResult = Result.Result<CreatePermissionResultOk, CreatePermissionResultErr>;

	public shared ({ caller }) func create_permission(permission : CreatePermissionData) : async CreatePermissionResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.CREATE_PERMISSION.id)))) return #err(#unauthorized);

		switch (permissionsService.create({ permission with createdBy = caller })) {
			case (#ok(permission)) {
				// TODO: Emit event

				#ok(permission);
			};
			case (#err(error)) #err(error);
		};
	};

	type DeletePermissionResultOk = ();

	type DeletePermissionResultErr = {
		#unauthorized;
		#permissionDoesNotExist;
		#permissionCouldNotBeDeleted;
	};

	type DeletePermissionResult = Result.Result<DeletePermissionResultOk, DeletePermissionResultErr>;

	public shared ({ caller }) func delete_permission(permissionId : Text) : async DeletePermissionResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.DELETE_PERMISSION.id)))) return #err(#unauthorized);

		if (not permissionsService.exists(permissionId)) return #err(#permissionDoesNotExist);

		switch (permissionsService.delete(permissionId)) {
			case (true) {
				let roles = rolesService.getAll();

				for (role in roles.vals()) {
					ignore rolesService.removePermission(role.name, permissionId);
				};

				let accesses = accessService.getAll();

				for (access in accesses.vals()) {
					ignore accessService.removePermission(access.identity, permissionId);
				};

				// TODO: Emit event

				#ok();
			};
			case (false) #ok();
		};
	};

	type GetRolesResultOk = [Roles.Role];

	type GetRolesResultErr = {
		#unauthorized;
	};

	type GetRolesResult = Result.Result<GetRolesResultOk, GetRolesResultErr>;

	public shared composite query ({ caller }) func get_roles() : async GetRolesResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.GET_ROLES.id)))) return #err(#unauthorized);

		return #ok(rolesService.getAll());
	};

	type CreateRoleData = {
		name : Text;
		description : Text;
		permissions : [Text];
	};

	type CreateRoleResultOk = Roles.Role;

	type CreateRoleResultErr = {
		#unauthorized;
		#duplicatedRoleName;
		#permissionsDoNotExist : [Text];
		#roleCouldNotBeCreated;
	};

	type CreateRoleResult = Result.Result<CreateRoleResultOk, CreateRoleResultErr>;

	public shared ({ caller }) func create_role(role : CreateRoleData) : async CreateRoleResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.CREATE_ROLE.id)))) return #err(#unauthorized);

		switch (rolesService.create({ role with createdBy = caller })) {
			case (#ok(role)) {
				// TODO: Emit event

				return #ok(role);
			};
			case (#err(error)) #err(error);
		};
	};

	type DeleteRoleResultOk = ();

	type DeleteRoleResultErr = {
		#unauthorized;
	};

	type DeleteRoleResult = Result.Result<DeleteRoleResultOk, DeleteRoleResultErr>;

	public shared ({ caller }) func delete_role(roleId : Text) : async DeleteRoleResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.DELETE_ROLE.id)))) return #err(#unauthorized);

		switch (rolesService.delete(roleId)) {
			case (true) {
				let accesses = accessService.getAll();

				for (access in accesses.vals()) {
					ignore accessService.removeRole(access.identity, roleId);
				};

				// TODO: Emit event

				return #ok();
			};
			case (false) return #ok();
		};
	};

	type AddPermissionToRoleResultOk = ();

	type AddPermissionToRoleResultErr = {
		#unauthorized;
		#permissionDoesNotExist;
		#permissionAlreadyAdded;
		#roleDoesNotExist;
	};

	type AddPermissionToRoleResult = Result.Result<AddPermissionToRoleResultOk, AddPermissionToRoleResultErr>;

	public shared ({ caller }) func add_permission_to_role(roleId : Text, permissionId : Text) : async AddPermissionToRoleResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.ADD_PERMISSION_TO_ROLE.id)))) return #err(#unauthorized);

		switch (rolesService.addPermission(roleId, permissionId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	type RemovePermissionFromRoleResultOk = ();

	type RemovePermissionFromRoleResultErr = {
		#unauthorized;
		#roleDoesNotExist;
	};

	type RemovePermissionFromRoleResult = Result.Result<RemovePermissionFromRoleResultOk, RemovePermissionFromRoleResultErr>;

	public shared ({ caller }) func remove_permission_from_role(roleId : Text, permissionId : Text) : async RemovePermissionFromRoleResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.REMOVE_PERMISSION_FROM_ROLE.id)))) return #err(#unauthorized);

		switch (rolesService.removePermission(roleId, permissionId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	type GetAccessListResultOk = [Access.Access];

	type GetAccessListResultErr = {
		#unauthorized;
	};

	type GetAccessListResult = Result.Result<GetAccessListResultOk, GetAccessListResultErr>;

	public shared composite query ({ caller }) func get_access_list() : async GetAccessListResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.GET_ACCESS_LIST.id)))) return #err(#unauthorized);

		return #ok(accessService.getAll());
	};

	type CreateAccessData = {
		identity : Principal;
		roles : [Text];
		permissions : [Text];
	};

	type CreateAccessResultOk = Access.Access;

	type CreateAccessResultErr = {
		#unauthorized;
		#accessAlreadyExists;
		#rolesDoNotExist : [Text];
		#permissionsDoNotExist : [Text];
		#accessCouldNotBeCreated;
	};

	type CreateAccessResult = Result.Result<CreateAccessResultOk, CreateAccessResultErr>;

	public shared ({ caller }) func create_access(data : CreateAccessData) : async CreateAccessResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.CREATE_ACCESS.id)))) return #err(#unauthorized);

		switch (accessService.create({ data with createdBy = caller })) {
			case (#ok(access)) {
				// TODO: Emit event

				#ok(access);
			};
			case (#err(error)) #err(error);
		};
	};

	type DeleteAccessResultOk = ();

	type DeleteAccessResultErr = {
		#unauthorized;
		#accessDoesNotExist;
		#accessCouldNotBeDeleted;
	};

	type DeleteAccessResult = Result.Result<DeleteAccessResultOk, DeleteAccessResultErr>;

	public shared ({ caller }) func delete_access(accessId : Principal) : async DeleteAccessResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.DELETE_ACCESS.id)))) return #err(#unauthorized);

		switch (accessService.delete(accessId)) {
			case (true) {
				// TODO: Emit event

				#ok();
			};
			case (false) return #ok();
		};
	};

	type GetAccessResultOk = ();

	type GetAccessResultErr = {
		#unauthorized;
		#accessDoesNotExist;
	};

	type GetAccessResult = Result.Result<GetAccessResultOk, GetAccessResultErr>;

	public shared ({ caller }) func get_access(accessId : Principal, status : Access.AccessStatus) : async GetAccessResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.CHANGE_ACCESS_STATUS.id)))) return #err(#unauthorized);

		return accessService.changeStatus(accessId, status);
	};

	type AddRoleToAccessResultOk = ();

	type AddRoleToAccessResultErr = {
		#unauthorized;
		#roleDoesNotExist;
		#accessDoesNotExist;
		#roleAlreadyAdded;
	};

	type AddRoleToAccessResult = Result.Result<AddRoleToAccessResultOk, AddRoleToAccessResultErr>;

	public shared ({ caller }) func add_role_to_access(accessId : Principal, roleId : Text) : async AddRoleToAccessResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.ADD_ROLE_TO_ACCESS.id)))) return #err(#unauthorized);

		switch (accessService.addRole(accessId, roleId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	type RemoveRoleFromAccessResultOk = ();

	type RemoveRoleFromAccessResultErr = {
		#unauthorized;
		#roleDoesNotExist;
		#accessDoesNotExist;
	};

	type RemoveRoleFromAccessResult = Result.Result<RemoveRoleFromAccessResultOk, RemoveRoleFromAccessResultErr>;

	public shared ({ caller }) func remove_role_from_access(accessId : Principal, roleId : Text) : async RemoveRoleFromAccessResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.REMOVE_ROLE_FROM_ACCESS.id)))) return #err(#unauthorized);

		switch (accessService.removeRole(accessId, roleId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	type AddPermissionToAccessResultOk = ();

	type AddPermissionToAccessResultErr = {
		#unauthorized;
		#permissionDoesNotExist;
		#accessDoesNotExist;
		#permissionAlreadyAdded;
	};

	type AddPermissionToAccessResult = Result.Result<AddPermissionToAccessResultOk, AddPermissionToAccessResultErr>;

	public shared ({ caller }) func add_permission_to_access(accessId : Principal, permissionId : Text) : async AddPermissionToAccessResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.ADD_PERMISSION_TO_ACCESS.id)))) return #err(#unauthorized);

		switch (accessService.addPermission(accessId, permissionId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	type RemovePermissionFromAccessResultOk = ();

	type RemovePermissionFromAccessResultErr = {
		#unauthorized;
		#permissionDoesNotExist;
		#accessDoesNotExist;
	};

	type RemovePermissionFromAccessResult = Result.Result<RemovePermissionFromAccessResultOk, RemovePermissionFromAccessResultErr>;

	public shared ({ caller }) func remove_permission_from_access(accessId : Principal, permissionId : Text) : async RemovePermissionFromAccessResult {
		if (not (await _iam.verify_access(caller, #permission(ACCESS_PERMISSION_LIST.REMOVE_PERMISSION_FROM_ACCESS.id)))) return #err(#unauthorized);

		switch (accessService.removePermission(accessId, permissionId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};
};
