import Types "./types";

module AccessPermissionModule {
	private type Permission = Types.Permission;

	public type PermissionList = {
		GET_PERMISSION_LIST : Permission;
		GET_POLICIES : Permission;
		CREATE_POLICY : Permission;
		GET_ROLES : Permission;
		CREATE_ROLE : Permission;
		DELETE_ROLE : Permission;
		ADD_POLICY_TO_ROLE : Permission;
		REMOVE_POLICY_FROM_ROLE : Permission;
		GET_ACCESS_LIST : Permission;
		CREATE_ACCESS : Permission;
		DELETE_ACCESS : Permission;
		CHANGE_ACCESS_ROLE : Permission;
	};

	public let PERMISSION_LIST : PermissionList = {
		GET_PERMISSION_LIST = {
			id = "workspace-iam:GetPolicyActions";
			description = "Grants permission to retrieve Policy Actions";
		};
		GET_POLICIES = { id = "workspace-iam:GetPolicies"; description = "Read all available actions" };
		CREATE_POLICY = { id = "workspace-iam:CreatePolicy"; description = "Read all available actions" };
		GET_ROLES = {
			id = "workspace-iam:GetRoles";
			description = "Read all available actions";
		};
		CREATE_ROLE = { id = "workspace-iam:CreateRole"; description = "Read all available actions" };
		DELETE_ROLE = { id = "workspace-iam:DeleteRole"; description = "Read all available actions" };
		ADD_POLICY_TO_ROLE = { id = "workspace-iam:AddPolicyToRole"; description = "Read all available actions" };
		REMOVE_POLICY_FROM_ROLE = {
			id = "workspace-iam:RemovePolicyFromRole";
			description = "Read all available actions";
		};
		GET_ACCESS_LIST = { id = "workspace-iam:GetAccessList"; description = "Read all available actions" };
		CREATE_ACCESS = { id = "workspace-iam:CreateAccess"; description = "Read all available actions" };
		DELETE_ACCESS = { id = "workspace-iam:CreateAccess"; description = "Read all available actions" };
		CHANGE_ACCESS_ROLE = { id = "workspace-iam:ChangeAccessRole"; description = "Read all available actions" };
	};
};
