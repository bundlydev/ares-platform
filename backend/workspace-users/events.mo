import Time "mo:base/Time";

import WorkspaceWebhooksModels "../workspace-webhooks/models";

module UsersEvents {
	type WebhookEvent<T> = WorkspaceWebhooksModels.WebhookEvent<T>;

	// Permission Events
	public type PermissionCreatedEventPayload = {
		action : Text;
		description : Text;
		createdBy : Principal;
		createdAt : Time.Time;
	};
	public type PermissionCreatedEvent = WebhookEvent<PermissionCreatedEventPayload>;

	public type PermissionDeletedEventPayload = {};
	public type PermissionDeletedEvent = WebhookEvent<PermissionDeletedEvent>;

	// Role Events
	public type RoleCreatedEventPayload = {};
	public type RoleCreatedEvent = WebhookEvent<RoleCreatedEventPayload>;

	public type RoleDeletedEventPayload = {};
	public type RoleDeletedEvent = WebhookEvent<RoleDeletedEventPayload>;

	public type PermissionAddedToRoleEventPayload = {};
	public type PermissionAddedToRoleEvent = WebhookEvent<PermissionAddedToRoleEventPayload>;

	public type PermissionRemovedFromRoleEventPayload = {};
	public type PermissionRemovedFromRoleEvent = WebhookEvent<PermissionRemovedFromRoleEventPayload>;

	// Access Events
	public type AccessCreatedEventPayload = {};
	public type AccessCreatedEvent = WebhookEvent<AccessCreatedEventPayload>;

	public type AccessDeletedEventPayload = {};
	public type AccessDeletedEvent = WebhookEvent<AccessDeletedEventPayload>;

	public type AccessStateChangedEventPayload = {};
	public type AccessStateChangedEvent = WebhookEvent<AccessStateChangedEventPayload>;

	public type RoleAddedToAccessEventPayload = {};
	public type RoleAddedToAccessEvent = WebhookEvent<RoleAddedToAccessEventPayload>;

	public type RoleRemovedFromAccessEventPayload = {};
	public type RoleRemovedFromAccessEvent = WebhookEvent<RoleRemovedFromAccessEventPayload>;

	public type PermissionAddedToAccessEventPayload = {};
	public type PermissionAddedToAccessEvent = WebhookEvent<PermissionAddedToAccessEventPayload>;

	public type Events = PermissionCreatedEvent or PermissionDeletedEvent or RoleCreatedEvent or RoleDeletedEvent or PermissionAddedToRoleEvent or PermissionRemovedFromRoleEvent or AccessCreatedEvent or AccessDeletedEvent or AccessStateChangedEvent or RoleAddedToAccessEvent or RoleRemovedFromAccessEvent or PermissionAddedToAccessEvent;
};
