import Time "mo:base/Time";

import Access "mo:access-management/Access";

module UsersEvents {
	// Permission Events
	public type PermissionCreatedEventPayload = {
		action : Text;
		description : Text;
		createdBy : Principal;
		createdAt : Time.Time;
	};

	public type PermissionDeletedEventPayload = {
		action : Text;
	};

	// Role Events
	public type RoleCreatedEventPayload = {
		name : Text;
		description : Text;
		permissions : [Text];
		createdBy : Principal;
		createdAt : Time.Time;
	};

	public type RoleDeletedEventPayload = {
		roleId : Text;
	};

	public type PermissionAddedToRoleEventPayload = {
		roleId : Text;
		permissionId : Text;
	};

	public type PermissionRemovedFromRoleEventPayload = {
		roleId : Text;
		permissionId : Text;
	};

	// Access Events
	public type AccessCreatedEventPayload = Access.Access;

	public type AccessDeletedEventPayload = {
		accessId : Principal;
	};

	public type AccessStatusChangedEventPayload = {
		accessId : Principal;
		status : Access.AccessStatus;
	};

	public type RoleAddedToAccessEventPayload = {
		accessId : Principal;
		roleId : Text;
	};

	public type RoleRemovedFromAccessEventPayload = {
		accessId : Principal;
		roleId : Text;
	};

	public type PermissionAddedToAccessEventPayload = {
		accessId : Principal;
		permissionId : Text;
	};

	public type PermissionRemovedFromAccessEventPayload = {
		accessId : Principal;
		permissionId : Text;
	};

	public type Events = {
		#permission : {
			#created : PermissionCreatedEventPayload;
			#deleted : PermissionDeletedEventPayload;
		};
		#role : {
			#created : RoleCreatedEventPayload;
			#deleted : RoleDeletedEventPayload;
			#permissionAdded : PermissionAddedToRoleEventPayload;
			#permissionRemoved : PermissionRemovedFromRoleEventPayload;
		};
		#access : {
			#created : AccessCreatedEventPayload;
			#deleted : AccessDeletedEventPayload;
			#statusChanged : AccessStatusChangedEventPayload;
			#roleAdded : RoleAddedToAccessEventPayload;
			#roleRemoved : RoleRemovedFromAccessEventPayload;
			#permissionAdded : PermissionAddedToAccessEventPayload;
			#permissionRemoved : PermissionRemovedFromAccessEventPayload;
		};
	};
};
