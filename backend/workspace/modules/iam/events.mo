import Access "../iam/access";

import CoreTypes "../core/types";
import Policy "./policy";
import Role "./role";

module IamEvents {
	type Event<T> = CoreTypes.Event<T>;

	// Policy Events
	public type PolicyCreatedEventPayload = Policy.Policy;
	public type PolicyCreatedEvent = Event<PolicyCreatedEventPayload>;

	// Role Events
	public type RoleCreatedEventPayload = Role.Role;
	public type RoleCreatedEvent = Event<RoleCreatedEventPayload>;

	public type RoleDeletedEventPayload = {
		rid : Text;
	};
	public type RoleDeletedEvent = Event<RoleDeletedEventPayload>;

	public type PolicyAddedToRoleEventPayload = {
		roleId : Text;
		policyId : Text;
	};

	public type PolicyAddedToRoleEvent = Event<PolicyAddedToRoleEventPayload>;

	public type PolicyRemovedFromRoleEventPayload = {
		roleId : Text;
		policyId : Text;
	};

	public type PolicyRemovedFromRoleEvent = Event<PolicyRemovedFromRoleEventPayload>;

	// Access Events
	public type AccessCreatedEventPayload = {
		identity : Principal;
		roleId : Text;
		itype : Access.AccessIdentityType;
	};

	public type AccessCreatedEvent = Event<AccessCreatedEventPayload>;

	public type AccessDeletedEventPayload = {
		identity : Principal;
		itype : Access.AccessIdentityType;
	};

	public type AccessDeletedEvent = Event<AccessDeletedEventPayload>;

	public type AccessRoleChangedEventPayload = {
		identity : Principal;
		roleId : Text;
	};

	public type AccessRoleChangedEvent = Event<AccessRoleChangedEventPayload>;
};
