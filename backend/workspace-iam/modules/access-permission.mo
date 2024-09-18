module AccessPermissionModule {
	public type AccessPermissionItem = {
		id : Text;
		description : Text;
	};

	public type AccessPermissionList = {
		GET_ACCESS_PERMISSION_LIST : AccessPermissionItem;
		GET_POLICIES : AccessPermissionItem;
		CREATE_POLICY : AccessPermissionItem;
		GET_ROLES : AccessPermissionItem;
		CREATE_ROLE : AccessPermissionItem;
		DELETE_ROLE : AccessPermissionItem;
		ADD_POLICY_TO_ROLE : AccessPermissionItem;
		REMOVE_POLICY_FROM_ROLE : AccessPermissionItem;
		GET_ACCESS_LIST : AccessPermissionItem;
		CREATE_ACCESS : AccessPermissionItem;
		DELETE_ACCESS : AccessPermissionItem;
		CHANGE_ACCESS_ROLE : AccessPermissionItem;
	};

	public let ACCESS_PERMISSION_LIST : AccessPermissionList = {
		GET_ACCESS_PERMISSION_LIST = {
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
