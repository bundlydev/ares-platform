import Time "mo:base/Time";

import Access "mo:access-management/Access";

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

	public type PermissionDeletedEventPayload = {
		action : Text;
	};
	public type PermissionDeletedEvent = Event<PermissionDeletedEventPayload>;

	// Role Events
	public type RoleCreatedEventPayload = {
		name : Text;
		description : Text;
		permissions : [Text];
		createdBy : Principal;
		createdAt : Time.Time;
	};
	public type RoleCreatedEvent = Event<RoleCreatedEventPayload>;

	public type RoleDeletedEventPayload = {
		roleId : Text;
	};
	public type RoleDeletedEvent = Event<RoleDeletedEventPayload>;

	public type PermissionAddedToRoleEventPayload = {
		roleId : Text;
		permissionId : Text;
	};
	public type PermissionAddedToRoleEvent = Event<PermissionAddedToRoleEventPayload>;

	public type PermissionRemovedFromRoleEventPayload = {
		roleId : Text;
		permissionId : Text;
	};
	public type PermissionRemovedFromRoleEvent = Event<PermissionRemovedFromRoleEventPayload>;

	// Access Events
	public type AccessCreatedEventPayload = Access.Access;
	public type AccessCreatedEvent = Event<AccessCreatedEventPayload>;

	public type AccessDeletedEventPayload = {
		accessId : Principal;
	};
	public type AccessDeletedEvent = Event<AccessDeletedEventPayload>;

	public type AccessStateChangedEventPayload = {
		accessId : Principal;
		status : Access.AccessStatus;
	};
	public type AccessStateChangedEvent = Event<AccessStateChangedEventPayload>;

	public type RoleAddedToAccessEventPayload = {
		accessId : Principal;
		roleId : Text;
	};
	public type RoleAddedToAccessEvent = Event<RoleAddedToAccessEventPayload>;

	public type RoleRemovedFromAccessEventPayload = {
		accessId : Principal;
		roleId : Text;
	};
	public type RoleRemovedFromAccessEvent = Event<RoleRemovedFromAccessEventPayload>;

	public type PermissionAddedToAccessEventPayload = {
		accessId : Principal;
		permissionId : Text;
	};
	public type PermissionAddedToAccessEvent = Event<PermissionAddedToAccessEventPayload>;

	public type PermissionRemovedFromAccessEventPayload = {
		accessId : Principal;
		permissionId : Text;
	};
	public type PermissionRemovedFromAccessEvent = Event<PermissionRemovedFromAccessEventPayload>;

	public type Events = PermissionCreatedEvent or PermissionDeletedEvent or RoleCreatedEvent or RoleDeletedEvent or PermissionAddedToRoleEvent or PermissionRemovedFromRoleEvent or AccessCreatedEvent or AccessDeletedEvent or AccessStateChangedEvent or RoleAddedToAccessEvent or RoleRemovedFromAccessEvent or PermissionAddedToAccessEvent or PermissionRemovedFromAccessEvent;
};
