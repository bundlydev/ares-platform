import Result "mo:base/Result";

import IamPermissions "../modules/iam/permissions";
import IamPolicy "../modules/iam/policy";
import IamRole "../modules/iam/role";
import IamAccess "../modules/iam/access";

module IamResults {
	public type GetIamActionsResultOk = IamPermissions.PermissionList;

	public type GetIamActionsResultErr = {
		#unauthorized;
	};

	public type GetIamActionsResult = Result.Result<GetIamActionsResultOk, GetIamActionsResultErr>;

	public type GetPermissionsResultOk = [IamPolicy.Policy];

	public type GetPermissionsResultErr = {
		#unauthorized;
	};

	public type GetPermissionsResult = Result.Result<GetPermissionsResultOk, GetPermissionsResultErr>;

	public type CreatePermissionResultOk = ();

	public type CreatePermissionResultErr = {
		#unauthorized;
		#permissionAlreadyAdded;
	};

	public type CreatePermissionResult = Result.Result<CreatePermissionResultOk, CreatePermissionResultErr>;

	public type GetRolesResultOk = [IamRole.Role];

	public type GetRolesResultErr = {
		#unauthorized;
	};

	public type GetRolesResult = Result.Result<GetRolesResultOk, GetRolesResultErr>;

	public type AddRoleResultOk = IamRole.Role;

	public type AddRoleResultErr = {
		#unauthorized;
		#roleAlreadyAdded;
	};

	public type AddRoleResult = Result.Result<AddRoleResultOk, AddRoleResultErr>;

	public type RemoveRoleResultOk = ();

	public type RemoveRoleResultErr = {
		#unauthorized;
		#roleNotFound;
	};

	public type RemoveRoleResult = Result.Result<RemoveRoleResultOk, RemoveRoleResultErr>;

	public type AddPermissionToRoleResultOk = ();

	public type AddPermissionToRoleResultErr = {
		#unauthorized;
		#roleNotFound;
		#permissionAlreadyGranted;
	};

	public type AddPermissionToRoleResult = Result.Result<AddPermissionToRoleResultOk, AddPermissionToRoleResultErr>;

	public type RemovePermissionFromRoleResultOk = ();

	public type RemovePermissionFromRoleResultErr = {
		#unauthorized;
		#permissionNotPreviouslyAssigned;
		#roleNotFound;
	};

	public type RemovePermissionFromRoleResult = Result.Result<RemovePermissionFromRoleResultOk, RemovePermissionFromRoleResultErr>;

	public type GetAccessListResultOk = [IamAccess.Access];

	public type GetAccessListResultErr = {
		#unauthorized;
	};

	public type GetAccessListResult = Result.Result<GetAccessListResultOk, GetAccessListResultErr>;

	public type CreateAccessResultOk = IamAccess.Access;

	public type CreateAccessResultErr = {
		#unauthorized;
		#accessAlreadyExists;
	};

	public type CreateAccessResult = Result.Result<CreateAccessResultOk, CreateAccessResultErr>;

	public type RemoveAccessResultOk = IamAccess.Access;

	public type RemoveAccessResultErr = {
		#unauthorized;
		#accessDoesNotExist;
	};

	public type RemoveAccessResult = Result.Result<RemoveAccessResultOk, RemoveAccessResultErr>;

	public type AssignRoleToPrincipalResultOk = ();

	public type AssignRoleToPrincipalResultErr = {
		#unauthorized;
		#roleAlreadyAssigned;
		#roleNotFound;
	};

	public type AssignRoleToPrincipalResult = Result.Result<AssignRoleToPrincipalResultOk, AssignRoleToPrincipalResultErr>;
};
