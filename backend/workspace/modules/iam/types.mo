module IamTypes {
	public type Permission = {
		id : Text;
		description : Text;
	};

	public type AccessType = {
		// Allow access to anounymous users
		#anonymous;
		// Allow access to users with specific permission
		#permission : Text;
	};
};
