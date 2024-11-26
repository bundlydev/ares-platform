import Policy "./policy";
import Role "./role";

import Access "../iam/access";

module IamEvents {
	// Policy Events
	public type PolicyCreatedEventPayload = Policy.Policy;

	// Role Events
	public type RoleCreatedEventPayload = Role.Role;

	public type RoleDeletedEventPayload = {
		rid : Text;
	};

	public type PolicyAddedToRoleEventPayload = {
		roleId : Text;
		policyId : Text;
	};

	public type PolicyRemovedFromRoleEventPayload = {
		roleId : Text;
		policyId : Text;
	};

	// Access Events
	public type AccessCreatedEventPayload = {
		identity : Principal;
		roleId : Text;
		itype : Access.AccessIdentityType;
	};

	public type AccessDeletedEventPayload = {
		identity : Principal;
		itype : Access.AccessIdentityType;
	};

	public type AccessRoleChangedEventPayload = {
		identity : Principal;
		roleId : Text;
	};

	public type Events = {
		#policy : {
			#created : PolicyCreatedEventPayload;
			#deleted : RoleDeletedEventPayload;
		};
		#role : {
			#created : RoleCreatedEventPayload;
			#deleted : RoleDeletedEventPayload;
			#policyAdded : PolicyAddedToRoleEventPayload;
			#policyRemoved : PolicyRemovedFromRoleEventPayload;
		};
		#access : {
			#created : AccessCreatedEventPayload;
			#deleted : AccessDeletedEventPayload;
			#roleChanged : AccessRoleChangedEventPayload;
		};
	};
};
