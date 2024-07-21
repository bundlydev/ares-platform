import Map "mo:map/Map";

import WorkspaceClass "../workspace/main";

module {
	public type Profile = {
		username : Text;
		email : Text;
		firstName : Text;
		lastName : Text;
	};

	public type Profiles = Map.Map<Principal, Profile>;

	public type Workspace = {
		ref : WorkspaceClass.WorkspaceClass;
		members : [Principal];
	};
	public type Workspaces = Map.Map<Principal, Workspace>;
};
