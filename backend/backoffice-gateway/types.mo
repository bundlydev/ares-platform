import Result "mo:base/Result";

import Models "./models";

module {
	public type GetProgileResponseOk = Models.Profile;

	public type GetProfileResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
	};

	public type GetProfileResponse = Result.Result<GetProgileResponseOk, GetProfileResponseErr>;

	public type CreateProfileData = {
		username : Text;
		firstName : Text;
		lastName : Text;
		email : Text;
	};

	public type CreateProfileResponseOk = ();

	public type CreateProfileResponseErr = {
		#userNotAuthenticated;
		#principalAlreadyRegistered;
		#usernameAlreadyExists;
		#requiredField : Text;
	};

	public type CreateProfileResponse = Result.Result<CreateProfileResponseOk, CreateProfileResponseErr>;

	public type GetMyWorkspacesResponseOkItem = Models.Workspace;

	public type GetMyWorkspacesResponseOk = [GetMyWorkspacesResponseOkItem];

	public type GetMyWorkspacesResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
	};

	public type GetMyWorkspacesResponse = Result.Result<GetMyWorkspacesResponseOk, GetMyWorkspacesResponseErr>;

	public type CreateWorkspaceData = {
		name : Text;
	};

	public type CreateWorkspaceResponseOk = ();

	public type CreateWorkspaceResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
		#requiredField : Text;
	};

	public type CreateWorkspaceResponse = Result.Result<CreateWorkspaceResponseOk, CreateWorkspaceResponseErr>;

	public type GetWorkspaceInfoResponseOk = {
		id : Principal;
		name : Text;
		members : [{
			id : Principal;
			roleId : Nat;
		}];
	};

	public type GetWorkspaceInfoResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
		#workspaceNotFound;
		#infoCannotBeRetrieved;
	};

	public type GetWorkspaceInfoResponse = Result.Result<GetWorkspaceInfoResponseOk, GetWorkspaceInfoResponseErr>;

	public type AddWorkspaceMemberResponseOk = ();

	public type AddWorkspaceMemberResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
		#unauthorized;
		#workspaceNotFound;
		#memberAlreadyRegistered;
	};

	public type AddWorkspaceMemberResponse = Result.Result<AddWorkspaceMemberResponseOk, AddWorkspaceMemberResponseErr>;

	public type RemoveWorkspaceMemberResponseOk = ();

	public type RemoveWorkspaceMemberResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
		#unauthorized;
		#workspaceNotFound;
		#memberNotFound;
		#ownersCannotBeRemoved;
	};

	public type RemoveWorkspaceMemberResponse = Result.Result<RemoveWorkspaceMemberResponseOk, RemoveWorkspaceMemberResponseErr>;
};
