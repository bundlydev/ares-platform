// Mops Modules
import Map "mo:map/Map";

// Actor Classes
import WorkspaceActor "../workspace/main";

module WorkspaceOrchestratorModels {
	public type Workspace = {
		wip : Principal;
		ref : WorkspaceActor.WorkspaceClass;
		name : Text;
		owner : Principal;
		members : [Principal];
	};

	public type WorkspaceCollection = Map.Map<Principal, Workspace>;
};
