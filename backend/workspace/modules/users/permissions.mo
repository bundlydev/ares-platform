import IamPermissionModule "../../../workspace-iam/modules/permission"

module PermissionModule {
	private type Permission = IamPermissionModule.Permission;

	public type PermissionList = {
		VERIFY_ACCESS : Permission;
		GET_PERMISSIONS : Permission;
		CREATE_PERMISSION : Permission;
		DELETE_PERMISSION : Permission;
		GET_ROLES : Permission;
		CREATE_ROLE : Permission;
		DELETE_ROLE : Permission;
		ADD_PERMISSION_TO_ROLE : Permission;
		REMOVE_PERMISSION_FROM_ROLE : Permission;
		GET_ACCESS_LIST : Permission;
		CREATE_ACCESS : Permission;
		DELETE_ACCESS : Permission;
		CHANGE_ACCESS_STATUS : Permission;
		ADD_ROLE_TO_ACCESS : Permission;
		REMOVE_ROLE_FROM_ACCESS : Permission;
		ADD_PERMISSION_TO_ACCESS : Permission;
		REMOVE_PERMISSION_FROM_ACCESS : Permission;
	};

	public let PERMISSION_LIST : PermissionList = {
		VERIFY_ACCESS = {
			id = "workspace-user-management:VerifyAccess";
			description = "Verify if a user has access to a resource";
		};
		GET_PERMISSIONS = {
			id = "workspace-user-management:GetPermissions";
			description = "Read all available permissions";
		};
		CREATE_PERMISSION = {
			id = "workspace-user-management:CreatePermission";
			description = "Create a new permission";
		};
		DELETE_PERMISSION = {
			id = "workspace-user-management:DeletePermission";
			description = "Delete a permission";
		};
		GET_ROLES = {
			id = "workspace-user-management:GetRoles";
			description = "Read all available roles";
		};
		CREATE_ROLE = {
			id = "workspace-user-management:CreateRole";
			description = "Create a new role";
		};
		DELETE_ROLE = {
			id = "workspace-user-management:DeleteRole";
			description = "Delete a role";
		};
		ADD_PERMISSION_TO_ROLE = {
			id = "workspace-user-management:AddPermissionToRole";
			description = "Add a permission to a role";
		};
		REMOVE_PERMISSION_FROM_ROLE = {
			id = "workspace-user-management:DeletePermissionFromRole";
			description = "Delete a permission from a role";
		};
		GET_ACCESS_LIST = {
			id = "workspace-user-management:GetAccessList";
			description = "Read all available access";
		};
		CREATE_ACCESS = {
			id = "workspace-user-management:CreateAccess";
			description = "Create a new access";
		};
		DELETE_ACCESS = {
			id = "workspace-user-management:DeleteAccess";
			description = "Delete an access";
		};
		CHANGE_ACCESS_STATUS = {
			id = "workspace-user-management:ChangeAccessStatus";
			description = "Change the status of an access";
		};
		ADD_ROLE_TO_ACCESS = {
			id = "workspace-user-management:AddRoleToAccess";
			description = "Add a role to an access";
		};
		REMOVE_ROLE_FROM_ACCESS = {
			id = "workspace-user-management:DeleteRoleFromAccess";
			description = "Delete a role from an access";
		};
		ADD_PERMISSION_TO_ACCESS = {
			id = "workspace-user-management:AddPermissionToAccess";
			description = "Add a permission to an access";
		};
		REMOVE_PERMISSION_FROM_ACCESS = {
			id = "workspace-user-management:DeletePermissionFromAccess";
			description = "Delete a permission from an access";
		};
	};
};
