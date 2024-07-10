import Result "mo:base/Result";

import Profile "services/profile";

module Types {
	public type GetProfileError = {
		#userNotAuthenticated;
		#profileNotFound;
	};

	public type GetProfileResponse = Result.Result<Profile.Profile, GetProfileError>;

	public type CreateProfileError = {
		#userNotAuthenticated;
		#principalAlreadyRegistered;
		#usernameAlreadyExists;
		#fieldRequired : Text;
	};

	public type CreateProfileResponse = Result.Result<Bool, CreateProfileError>;
};
