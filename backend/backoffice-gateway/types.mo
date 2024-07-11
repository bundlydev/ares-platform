import Result "mo:base/Result";

import Profile "./services/profile";
import Workspace "./services/workspace";

module {
	public type GetProgileResponseOk = Profile.Profile;
	public type GetProfileResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
	};

	public type GetProfileResponse = Result.Result<GetProgileResponseOk, GetProfileResponseErr>;

	public type CreateProfileResponseOk = ();

	public type CreateProfileResponseErr = {
		#userNotAuthenticated;
		#principalAlreadyRegistered;
		#usernameAlreadyExists;
		#fieldRequired : Text;
	};

	public type CreateProfileResponse = Result.Result<CreateProfileResponseOk, CreateProfileResponseErr>;

	public type GetMyWorkspacesResponseOkItem = Workspace.Workspace;

	public type GetMyWorkspacesResponseOk = [GetMyWorkspacesResponseOkItem];

	public type GetMyWorkspacesResponseErr = {
		#userNotAuthenticated;
	};

	public type GetMyWorkspacesResponse = Result.Result<GetMyWorkspacesResponseOk, GetMyWorkspacesResponseErr>;

	public type CreateWorkspaceData = {
		name : Text;
	};

	public type CreateWorkspaceResponseOk = ();

	public type CreateWorkspaceResponseErr = {
		#userNotAuthenticated;
	};

	public type CreateWorkspaceResponse = Result.Result<CreateWorkspaceResponseOk, CreateWorkspaceResponseErr>;
};
