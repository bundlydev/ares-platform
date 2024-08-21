// Mops Modules
import Map "mo:map/Map";

// Actor Classes
import WorkspaceIam "../workspace-iam/main";

module WorkspaceOrchestratorModels {
	public type Workspace = {
		wip : Principal;
		name : Text;
		owner : Principal;
		members : [Principal];
		canisters : {
			iam : WorkspaceIam.IamActorClass;
		};
	};

	public type WorkspaceCollection = Map.Map<Principal, Workspace>;
};
