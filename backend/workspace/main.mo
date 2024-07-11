import Principal "mo:base/Principal";

import Map "mo:map/Map";
import TextValidator "mo:validators/Text";

import Profile "./services/profile";
import Types "./types";

actor {
	// Database
	stable let _profiles = Map.new<Principal, Profile.Profile>();

	// Services
	private let profileService = Profile.ProfileService(_profiles);

	public shared query ({ caller }) func getProfile() : async Types.GetProfileResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);

		let profile = profileService.getById(caller);

		switch profile {
			case (?profile) {
				#ok(profile);
			};
			case null {
				#err(#profileNotFound);
			};
		};
	};

	public shared ({ caller }) func createProfile(data : Profile.CreateProfileData) : async Types.CreateProfileResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);

		// TODO: Should validations be done here or in the profile service?

		if (profileService.getById(caller) != null) return #err(#principalAlreadyRegistered);

		if (TextValidator.isEmpty(data.username)) {
			return #err(#fieldRequired("username"));
		} else if (TextValidator.isEmpty(data.email)) {
			return #err(#fieldRequired("email"));
		} else if (TextValidator.isEmpty(data.firstName)) {
			return #err(#fieldRequired("firstName"));
		} else if (TextValidator.isEmpty(data.lastName)) {
			return #err(#fieldRequired("lastName"));
		};

		if (profileService.getByUsername(data.username) != null) return #err(#usernameAlreadyExists);

		let newProfile : Profile.Profile = {
			username = data.username;
			firstName = data.firstName;
			lastName = data.lastName;
			email = data.email;
		};

		profileService.create(caller, newProfile);

		#ok();
	};
};
