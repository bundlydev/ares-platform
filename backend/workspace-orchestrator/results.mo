// Base Modules
import Result "mo:base/Result";

module WorkspaceOrchestratorTypes {
	public type GetMyWorkspacesResultOkItem = {
		wip : Principal;
		name : Text;
	};

	public type GetMyWorkspacesResultOk = [GetMyWorkspacesResultOkItem];

	public type GetMyWorkspacesResultErr = {
		#unauthorized;
		#profileNotFound;
	};

	public type GetMyWorkspacesResult = Result.Result<GetMyWorkspacesResultOk, GetMyWorkspacesResultErr>;

	public type GetWorkspaceInfoResultOk = {
		wip : Principal;
		ref : Principal;
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

	public type CreateWorkspaceResultOk = {
		wip : Principal;
		ref : Principal;
		name : Text;
		owner : Principal;
		members : [Principal];
		canisters : {
			iam : Principal;
			users : Principal;
			webhooks : Principal;
		};
	};

	public type CreateWorkspaceResultErr = {
		#unauthorized;
		#profileNotFound;
		#requiredField : Text;
	};

	public type CreateWorkspaceResult = Result.Result<CreateWorkspaceResultOk, CreateWorkspaceResultErr>;

	public type DeleteWorkspaceResultOk = {
		refundedCycles : Nat;
	};

	public type DeleteWorkspaceResultErr = {
		#unauthorized;
		#profileNotFound;
		#workspaceNotFound;
	};

	public type DeleteWorkspaceResult = Result.Result<DeleteWorkspaceResultOk, DeleteWorkspaceResultErr>;

	public type GetMyBalanceResultOk = {
		balance : Nat;
	};

	public type GetMyBalanceResultErr = {
		#unauthorized;
		#profileNotFound;
	};

	public type GetMyBalanceResult = Result.Result<GetMyBalanceResultOk, GetMyBalanceResultErr>;
};
