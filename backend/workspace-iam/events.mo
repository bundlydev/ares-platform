import AccessModule "./modules/access";

module WorkspaceIamEvents {
	public type WorkspaceAccessCreated = {
		identity : Principal;
		roleId : Text;
		itype : AccessModule.AccessIdentityType;
	};

	public type WorkspaceAccessRemoved = {
		identity : Principal;
		roleId : Text;
		itype : AccessModule.AccessIdentityType;
	};

	public type EventVariants = {
		#workspaceAccessCreated : WorkspaceAccessCreated;
		#workspaceAccessRemoved : WorkspaceAccessRemoved;
	};
};
