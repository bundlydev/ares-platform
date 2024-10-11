import IamPermissionModule "../workspace-iam/modules/permission";

module PermissiosnModule {
	private type Permission = IamPermissionModule.Permission;

	public type PermissionList = {
		GET_WEBHOOK_LIST : Permission;
		REGISTER_WEBHOOK : Permission;
		REMOVE_WEBHOOK : Permission;
	};

	public let PERMISSION_LIST : PermissionList = {
		GET_WEBHOOK_LIST = {
			id = "workspace-webhooks:GetWebhookList";
			description = "Grants permission to retrieve Webhook List";
		};
		REGISTER_WEBHOOK = {
			id = "workspace-webhooks:RegisterWebhook";
			description = "Grants permission to register a new Webhook";
		};
		REMOVE_WEBHOOK = {
			id = "workspace-webhooks:RemoveWebhook";
			description = "Grants permission to remove a Webhook";
		};
	};
};
