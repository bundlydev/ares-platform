// Mops Modules
import Map "mo:map/Map";

// Actor Classes
import WorkspaceIam "../workspace-iam/main";
import WorkspaceUsers "../workspace-users/main";
import WorkspaceWebhooks "../workspace-webhooks/main";

module WorkspaceOrchestratorModels {
	public type WorkspaceCanisters = {
		iam : WorkspaceIam.IamActorClass;
		users : WorkspaceUsers.WorkspaceUsersActorClass;
		webhooks : WorkspaceWebhooks.WorkspaceWebhooksActorClass;
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
