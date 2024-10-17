import Time "mo:base/Time";

import CoreTypes "../core/types";

module UsersEvents {
	type Event<T> = CoreTypes.Event<T>;

	// Permission Events
	public type PermissionCreatedEventPayload = {
		action : Text;
		description : Text;
		createdBy : Principal;
		createdAt : Time.Time;
	};
	public type PermissionCreatedEvent = Event<PermissionCreatedEventPayload>;

	public type PermissionDeletedEventPayload = {};
	public type PermissionDeletedEvent = Event<PermissionDeletedEvent>;

	// Role Events
	public type RoleCreatedEventPayload = {};
	public type RoleCreatedEvent = Event<RoleCreatedEventPayload>;

	public type RoleDeletedEventPayload = {};
	public type RoleDeletedEvent = Event<RoleDeletedEventPayload>;

	public type PermissionAddedToRoleEventPayload = {};
	public type PermissionAddedToRoleEvent = Event<PermissionAddedToRoleEventPayload>;

	public type PermissionRemovedFromRoleEventPayload = {};
	public type PermissionRemovedFromRoleEvent = Event<PermissionRemovedFromRoleEventPayload>;

	// Access Events
	public type AccessCreatedEventPayload = {};
	public type AccessCreatedEvent = Event<AccessCreatedEventPayload>;

	public type AccessDeletedEventPayload = {};
	public type AccessDeletedEvent = Event<AccessDeletedEventPayload>;

	public type AccessStateChangedEventPayload = {};
	public type AccessStateChangedEvent = Event<AccessStateChangedEventPayload>;

	public type RoleAddedToAccessEventPayload = {};
	public type RoleAddedToAccessEvent = Event<RoleAddedToAccessEventPayload>;

	public type RoleRemovedFromAccessEventPayload = {};
	public type RoleRemovedFromAccessEvent = Event<RoleRemovedFromAccessEventPayload>;

	public type PermissionAddedToAccessEventPayload = {};
	public type PermissionAddedToAccessEvent = Event<PermissionAddedToAccessEventPayload>;

	public type Events = PermissionCreatedEvent or PermissionDeletedEvent or RoleCreatedEvent or RoleDeletedEvent or PermissionAddedToRoleEvent or PermissionRemovedFromRoleEvent or AccessCreatedEvent or AccessDeletedEvent or AccessStateChangedEvent or RoleAddedToAccessEvent or RoleRemovedFromAccessEvent or PermissionAddedToAccessEvent;
};
