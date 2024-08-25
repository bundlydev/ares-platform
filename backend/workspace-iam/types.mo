module WorkspaceIamTypes {
	public type ActorContext = {
		creator : Principal;
		owner : Principal;
	};

	public type AccessType = {
		// Allow access to anounymous users
		#anonymous;
		// Allow access to users with specific permission
		#permission : Text;
	};
};
