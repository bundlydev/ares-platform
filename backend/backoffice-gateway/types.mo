import Result "mo:base/Result";

import Role "../workspace/role";

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

	public type FindProfilesByUsernameChunkResponseOk = [{
		id : Principal;
		username : Text;
	}];

	public type FindProfilesByUsernameChunkResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
		#chunkTooShort;
	};

	public type FindProfilesByUsernameChunkResponse = Result.Result<FindProfilesByUsernameChunkResponseOk, FindProfilesByUsernameChunkResponseErr>;

	public type GetMyWorkspacesResponseOkItem = {
		id : Principal;
		members : [Principal];
	};

	public type GetMyWorkspacesResponseOk = [GetMyWorkspacesResponseOkItem];

	public type GetMyWorkspacesResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
	};

	public type GetMyWorkspacesResponse = Result.Result<GetMyWorkspacesResponseOk, GetMyWorkspacesResponseErr>;

	public type CreateWorkspaceData = {
		name : Text;
	};

	public type CreateWorkspaceResponseOk = {
		workspaceId : Principal;
	};

	public type CreateWorkspaceResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
		#requiredField : Text;
	};

	public type CreateWorkspaceResponse = Result.Result<CreateWorkspaceResponseOk, CreateWorkspaceResponseErr>;

	public type GetWorkspaceInfoResponseOk = {
		id : Principal;
		name : Text;
	};

	public type GetWorkspaceInfoResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
		#workspaceNotFound;
		#unauthorized;
	};

	public type GetWorkspaceInfoResponse = Result.Result<GetWorkspaceInfoResponseOk, GetWorkspaceInfoResponseErr>;

	public type GetWorkspaceMembersResponseOk = [{
		id : Principal;
		name : Text;
		role : {
			id : Nat;
			name : Text;
		};
	}];

	public type GetWorkspaceMembersResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
		#workspaceNotFound;
		#errorGettingMembers;
		#errorGettingRoles;
		#errorGettingMembersInfo;
	};

	public type GetWorkspaceMembersResponse = Result.Result<GetWorkspaceMembersResponseOk, GetWorkspaceMembersResponseErr>;

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

	public type GetWorkspaceRolesResponseOk = [Role.Role];

	public type GetWorkspaceRolesResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
		#workspaceNotFound;
		#unauthorized;
	};

	public type GetWorkspaceRolesResponse = Result.Result<GetWorkspaceRolesResponseOk, GetWorkspaceRolesResponseErr>;
};
