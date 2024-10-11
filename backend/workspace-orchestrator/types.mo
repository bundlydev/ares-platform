// Base Modules
import Result "mo:base/Result";

module WorkspaceOrchestratorTypes {
	public type GetMyWorkspacesResponseOkItem = {
		wip : Principal;
		name : Text;
	};

	public type GetMyWorkspacesResponseOk = [GetMyWorkspacesResponseOkItem];

	public type GetMyWorkspacesResponseErr = {
		#unauthorized;
		#profileNotFound;
	};

	public type GetMyWorkspacesResponse = Result.Result<GetMyWorkspacesResponseOk, GetMyWorkspacesResponseErr>;

	public type GetWorkspaceInfoResultOk = {
		wip : Principal;
		name : Text;
		owner : Principal;
		members : [Principal];
		canisters : {
			iam : Principal;
			users : Principal;
			webhooks : Principal;
		};
	};

	public type GetWorkspaceInfoResultErr = {
		#unauthorized;
		#workspaceNotFound;
	};

	public type GetWorkspaceInfoResult = Result.Result<GetWorkspaceInfoResultOk, GetWorkspaceInfoResultErr>;

	public type PrepareCanisterDeletionOk = {
		refundedCycles : Nat;
	};

	public type PrepareDeletionCanisterErr = {
		#unauthorized;
	};

	public type PrepareCanisterDeletionResult = Result.Result<PrepareCanisterDeletionOk, PrepareDeletionCanisterErr>;

	public type CreateWorkspaceData = {
		name : Text;
	};

	public type CreateWorkspaceResponseOk = {
		wip : Principal;
		name : Text;
		owner : Principal;
		members : [Principal];
		canisters : {
			iam : Principal;
			users : Principal;
			webhooks : Principal;
		};
	};

	public type CreateWorkspaceResponseErr = {
		#unauthorized;
		#profileNotFound;
		#requiredField : Text;
	};

	public type CreateWorkspaceResponse = Result.Result<CreateWorkspaceResponseOk, CreateWorkspaceResponseErr>;

	public type DeleteWorkspaceResponseOk = {
		refundedCycles : Nat;
	};

	public type DeleteWorkspaceResponseErr = {
		#unauthorized;
		#profileNotFound;
		#workspaceNotFound;
	};

	public type DeleteWorkspaceResponse = Result.Result<DeleteWorkspaceResponseOk, DeleteWorkspaceResponseErr>;

	public type GetMyBalanceResponseOk = {
		balance : Nat;
	};

	public type GetMyBalanceResponseErr = {
		#unauthorized;
		#profileNotFound;
	};

	public type GetMyBalanceResponse = Result.Result<GetMyBalanceResponseOk, GetMyBalanceResponseErr>;
};
