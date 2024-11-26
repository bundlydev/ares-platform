import Result "mo:base/Result";

import Permissions "mo:access-management/Permissions";
import Roles "mo:access-management/Roles";
import Access "mo:access-management/Access";

module UsersResults {
	public type HasAccessResultOk = Bool;

	public type HasAccessResultErr = {
		#unauthorized;
	};

	public type HasAccessResult = Result.Result<HasAccessResultOk, HasAccessResultErr>;

	public type GetPermissionsResultOk = [Permissions.Permission];

	public type GetPermissionsResultErr = {
		#unauthorized;
	};

	public type GetPermissionsResult = Result.Result<GetPermissionsResultOk, GetPermissionsResultErr>;

	public type CreatePermissionData = {
		action : Text;
		description : Text;
	};

	public type CreatePermissionResultOk = Permissions.Permission;

	public type CreatePermissionResultErr = {
		#unauthorized;
		#actionAlreadyRegistered;
	};

	public type CreatePermissionResult = Result.Result<CreatePermissionResultOk, CreatePermissionResultErr>;

	public type DeletePermissionResultOk = ();

	public type DeletePermissionResultErr = {
		#unauthorized;
		#permissionDoesNotExist;
		#permissionCouldNotBeDeleted;
	};

	public type DeletePermissionResult = Result.Result<DeletePermissionResultOk, DeletePermissionResultErr>;

	public type GetRolesResultOk = [Roles.Role];

	public type GetRolesResultErr = {
		#unauthorized;
	};

	public type GetRolesResult = Result.Result<GetRolesResultOk, GetRolesResultErr>;

	public type CreateRoleData = {
		name : Text;
		description : Text;
		permissions : [Text];
	};

	public type CreateRoleResultOk = Roles.Role;

	public type CreateRoleResultErr = {
		#unauthorized;
		#duplicatedRoleName;
		#permissionsDoNotExist : [Text];
		#roleCouldNotBeCreated;
	};

	public type CreateRoleResult = Result.Result<CreateRoleResultOk, CreateRoleResultErr>;

	public type DeleteRoleResultOk = ();

	public type DeleteRoleResultErr = {
		#unauthorized;
	};

	public type DeleteRoleResult = Result.Result<DeleteRoleResultOk, DeleteRoleResultErr>;

	public type AddPermissionToRoleResultOk = ();

	public type AddPermissionToRoleResultErr = {
		#unauthorized;
		#permissionDoesNotExist;
		#permissionAlreadyAdded;
		#roleDoesNotExist;
	};

	public type AddPermissionToRoleResult = Result.Result<AddPermissionToRoleResultOk, AddPermissionToRoleResultErr>;

	public type RemovePermissionFromRoleResultOk = ();

	public type RemovePermissionFromRoleResultErr = {
		#unauthorized;
		#roleDoesNotExist;
	};

	public type RemovePermissionFromRoleResult = Result.Result<RemovePermissionFromRoleResultOk, RemovePermissionFromRoleResultErr>;

	public type GetAccessListResultOk = [Access.Access];

	public type GetAccessListResultErr = {
		#unauthorized;
	};

	public type GetAccessListResult = Result.Result<GetAccessListResultOk, GetAccessListResultErr>;

	public type CreateAccessData = {
		identity : Principal;
		roles : [Text];
		permissions : [Text];
	};

	public type CreateAccessResultOk = Access.Access;

	public type CreateAccessResultErr = {
		#unauthorized;
		#accessAlreadyExists;
		#rolesDoNotExist : [Text];
		#permissionsDoNotExist : [Text];
		#accessCouldNotBeCreated;
	};

	public type CreateAccessResult = Result.Result<CreateAccessResultOk, CreateAccessResultErr>;

	public type DeleteAccessResultOk = ();

	public type DeleteAccessResultErr = {
		#unauthorized;
		#accessDoesNotExist;
		#accessCouldNotBeDeleted;
	};

	public type DeleteAccessResult = Result.Result<DeleteAccessResultOk, DeleteAccessResultErr>;

	public type GetAccessResultOk = ();

	public type GetAccessResultErr = {
		#unauthorized;
		#accessDoesNotExist;
	};

	public type GetAccessResult = Result.Result<GetAccessResultOk, GetAccessResultErr>;

	public type AddRoleToAccessResultOk = ();

	public type AddRoleToAccessResultErr = {
		#unauthorized;
		#roleDoesNotExist;
		#accessDoesNotExist;
		#roleAlreadyAdded;
	};

	public type AddRoleToAccessResult = Result.Result<AddRoleToAccessResultOk, AddRoleToAccessResultErr>;

	public type RemoveRoleFromAccessResultOk = ();

	public type RemoveRoleFromAccessResultErr = {
		#unauthorized;
		#roleDoesNotExist;
		#accessDoesNotExist;
	};

	public type RemoveRoleFromAccessResult = Result.Result<RemoveRoleFromAccessResultOk, RemoveRoleFromAccessResultErr>;

	public type AddPermissionToAccessResultOk = ();

	public type AddPermissionToAccessResultErr = {
		#unauthorized;
		#permissionDoesNotExist;
		#accessDoesNotExist;
		#permissionAlreadyAdded;
	};

	public type AddPermissionToAccessResult = Result.Result<AddPermissionToAccessResultOk, AddPermissionToAccessResultErr>;

	public type RemovePermissionFromAccessResultOk = ();

	public type RemovePermissionFromAccessResultErr = {
		#unauthorized;
		#permissionDoesNotExist;
		#accessDoesNotExist;
	};

	public type RemovePermissionFromAccessResult = Result.Result<RemovePermissionFromAccessResultOk, RemovePermissionFromAccessResultErr>;
};
