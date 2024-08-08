import Map "mo:map/Map";

import WorkspaceClass "../workspace/main";

module {
	public type ProfileEntity = {
		username : Text;
		email : Text;
		firstName : Text;
		lastName : Text;
	};

	public type ProfileStorage = Map.Map<Principal, ProfileEntity>;

	public type WorkspaceEntity = {
		ref : WorkspaceClass.WorkspaceClass;
		members : [Principal];
	};

	public type WorkspaceStorage = Map.Map<Principal, WorkspaceEntity>;
};
