import Principal "mo:base/Principal";
import Iter "mo:base/Iter";

import Map "mo:map/Map";
import TextValidator "mo:validators/Text";

import Profile "./services/profile";
import Workspace "./services/workspace";
import Types "./types";

actor {
	// Database
	stable let _profiles = Map.new<Principal, Profile.Profile>();
	stable let _workspaces = Map.new<Principal, Workspace.Workspace>();

	// Services
	private let profileService = Profile.ProfileService(_profiles);
	private let workspaceService = Workspace.WorkspaceService(_workspaces);

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

	public shared query ({ caller }) func getMyWorkspaces() : async Types.GetMyWorkspacesResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);

		let workspaceMap = workspaceService.findByMember(caller);
		let workspaceIter = Map.vals(workspaceMap);
		let workspaces = Iter.toArray(workspaceIter);

		return #ok(workspaces);
	};

	public shared ({ caller }) func createWorkspace(data : Types.CreateWorkspaceData) : async Types.CreateWorkspaceResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);

		let newWorkspace : Workspace.CreateWorkspaceData = {
			name = data.name;
			owner = caller;
		};

		let _workspace = workspaceService.create(newWorkspace);

		#ok(());
	};
};
