// Base Modules
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

import WorkspaceOrchestratorTypes "../workspace-orchestrator/types";

import Types "./types";
import { PERMISSION_LIST } "./permissions";

shared ({ caller = creator }) actor class WorkspaceUsersActorClass(owner : Principal, iam : Principal) = Self {
	// Actors
	private let ic = actor ("aaaaa-aa") : IC.Service;
	private stable let _iam = actor (Principal.toText(iam)) : WorkspaceIam.IamActorClass;

	// State
	private stable let _creator = creator;
	private stable let _owner = owner;
	private stable var _permissions : Permissions.PermissionsRepository = Set.new();
	private stable var _roles : Roles.RolesRepository = Map.new();
	private stable var _accessList : Access.AccessRepository = Map.new();

	// Services
	private let permissionsService = Permissions.PermissionsService(_permissions);
	private let rolesService = Roles.RolesService(_roles, permissionsService);
	private let accessService = Access.AccessService(_accessList, rolesService, permissionsService);

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

	public shared composite query ({ caller }) func has_access(identity : Principal, permission : Text) : async Types.HasAccessResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.VERIFY_ACCESS.id)))) return #err(#unauthorized);

		return #ok(accessService.hasPermission(identity, permission));
	};

	public shared composite query ({ caller }) func get_permissions() : async Types.GetPermissionsResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.GET_PERMISSIONS.id)))) return #err(#unauthorized);

		return #ok(permissionsService.getAll());
	};

	public shared ({ caller }) func create_permission(permission : Types.CreatePermissionData) : async Types.CreatePermissionResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.CREATE_PERMISSION.id)))) return #err(#unauthorized);

		switch (permissionsService.create({ permission with createdBy = caller })) {
			case (#ok(permission)) {
				// TODO: Emit event

				#ok(permission);
			};
			case (#err(error)) #err(error);
		};
	};

	public shared ({ caller }) func delete_permission(permissionId : Text) : async Types.DeletePermissionResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.DELETE_PERMISSION.id)))) return #err(#unauthorized);

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

	public shared composite query ({ caller }) func get_roles() : async Types.GetRolesResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.GET_ROLES.id)))) return #err(#unauthorized);

		return #ok(rolesService.getAll());
	};

	public shared ({ caller }) func create_role(role : Types.CreateRoleData) : async Types.CreateRoleResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.CREATE_ROLE.id)))) return #err(#unauthorized);

		switch (rolesService.create({ role with createdBy = caller })) {
			case (#ok(role)) {
				// TODO: Emit event

				return #ok(role);
			};
			case (#err(error)) #err(error);
		};
	};

	public shared ({ caller }) func delete_role(roleId : Text) : async Types.DeleteRoleResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.DELETE_ROLE.id)))) return #err(#unauthorized);

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

	public shared ({ caller }) func add_permission_to_role(roleId : Text, permissionId : Text) : async Types.AddPermissionToRoleResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.ADD_PERMISSION_TO_ROLE.id)))) return #err(#unauthorized);

		switch (rolesService.addPermission(roleId, permissionId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	public shared ({ caller }) func remove_permission_from_role(roleId : Text, permissionId : Text) : async Types.RemovePermissionFromRoleResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.REMOVE_PERMISSION_FROM_ROLE.id)))) return #err(#unauthorized);

		switch (rolesService.removePermission(roleId, permissionId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	public shared composite query ({ caller }) func get_access_list() : async Types.GetAccessListResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.GET_ACCESS_LIST.id)))) return #err(#unauthorized);

		return #ok(accessService.getAll());
	};

	public shared ({ caller }) func create_access(data : Types.CreateAccessData) : async Types.CreateAccessResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.CREATE_ACCESS.id)))) return #err(#unauthorized);

		switch (accessService.create({ data with createdBy = caller })) {
			case (#ok(access)) {

				#ok(access);
			};
			case (#err(error)) #err(error);
		};
	};

	public shared ({ caller }) func delete_access(accessId : Principal) : async Types.DeleteAccessResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.DELETE_ACCESS.id)))) return #err(#unauthorized);

		switch (accessService.delete(accessId)) {
			case (true) {
				// TODO: Emit event

				#ok();
			};
			case (false) return #ok();
		};
	};

	public shared ({ caller }) func change_access_status(accessId : Principal, status : Access.AccessStatus) : async Types.GetAccessResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.CHANGE_ACCESS_STATUS.id)))) return #err(#unauthorized);

		return accessService.changeStatus(accessId, status);
	};

	public shared ({ caller }) func add_role_to_access(accessId : Principal, roleId : Text) : async Types.AddRoleToAccessResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.ADD_ROLE_TO_ACCESS.id)))) return #err(#unauthorized);

		switch (accessService.addRole(accessId, roleId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	public shared ({ caller }) func remove_role_from_access(accessId : Principal, roleId : Text) : async Types.RemoveRoleFromAccessResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.REMOVE_ROLE_FROM_ACCESS.id)))) return #err(#unauthorized);

		switch (accessService.removeRole(accessId, roleId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	public shared ({ caller }) func add_permission_to_access(accessId : Principal, permissionId : Text) : async Types.AddPermissionToAccessResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.ADD_PERMISSION_TO_ACCESS.id)))) return #err(#unauthorized);

		switch (accessService.addPermission(accessId, permissionId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};

	public shared ({ caller }) func remove_permission_from_access(accessId : Principal, permissionId : Text) : async Types.RemovePermissionFromAccessResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.REMOVE_PERMISSION_FROM_ACCESS.id)))) return #err(#unauthorized);

		switch (accessService.removePermission(accessId, permissionId)) {
			case (#ok()) {
				// TODO: Emit event

				#ok();
			};
			case (#err(error)) #err(error);
		};
	};
};
