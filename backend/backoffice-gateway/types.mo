// Base Modules
import Result "mo:base/Result";

import Models "./models";

module {
	public type GetProfileByIdResultOk = Models.ProfileEntity;

	public type GetProfileByIdResultErr = {
		#userNotAuthenticated;
		#profileNotFound;
	};

	public type GetProfileByIdResult = Result.Result<GetProfileByIdResultOk, GetProfileByIdResultErr>;

	public type GetProgileResponseOk = Models.ProfileEntity;

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
		#emailAlreadyExists;
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
		name : Text;
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

	public type DeleteWorkspaceResponseOk = {
		refundedCycles : Nat;
	};

	public type DeleteWorkspaceResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
		#workspaceNotFound;
		#unauthorized;
	};

	public type DeleteWorkspaceResponse = Result.Result<DeleteWorkspaceResponseOk, DeleteWorkspaceResponseErr>;

	public type GetMyBalanceResponseOk = {
		balance : Nat;
	};

	public type GetMyBalanceResponseErr = {
		#userNotAuthenticated;
		#profileNotFound;
	};

	public type GetMyBalanceResponse = Result.Result<GetMyBalanceResponseOk, GetMyBalanceResponseErr>;

	public type WebhookHandlerResultOk = ();

	public type WebhookHandlerResultErr = {
		#unauthorized;
	};

	public type WebhookHandlerResult = Result.Result<WebhookHandlerResultOk, WebhookHandlerResultErr>;
};
