// Mops Modules
import Map "mo:map/Map";

// Actor Classes
import WorkspaceIam "../workspace-iam/main";
import WorkspaceUserManagement "../workspace-user-management/main";

module WorkspaceOrchestratorModels {
	public type WorkspaceCanisters = {
		iam : WorkspaceIam.IamActorClass;
		user_management : WorkspaceUserManagement.WorkspaceUserManagementActorClass;
	};

	public type Workspace = {
		wip : Principal;
		name : Text;
		owner : Principal;
		members : [Principal];
		canisters : WorkspaceCanisters;
	};

	public type WorkspaceCollection = Map.Map<Principal, Workspace>;
};
