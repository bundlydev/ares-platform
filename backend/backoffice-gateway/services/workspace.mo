import Map "mo:map/Map";
import { phash } "mo:map/Map";
import Principal "mo:base/Principal";
import Cycles "mo:base/ExperimentalCycles";
import Array "mo:base/Array";

import Workspace "../../workspace/main";

module {
	public type Workspace = {
		// principal : Principal;
		// name : Text;
		ref : Workspace.WorkspaceClass;
		members : [Principal];
	};

	public type Workspaces = Map.Map<Principal, Workspace>;

	public type CreateWorkspaceData = {
		name : Text;
		owner : Principal;
	};

	public class WorkspaceService(_workspaces : Workspaces) {
		public func create(data : CreateWorkspaceData) : async () {
			Cycles.add(113_846_199_230);

			let workspace = await Workspace.WorkspaceClass(data.name, data.owner);
			let workspaceId = Principal.fromActor(workspace);

			let newWorkspace : Workspace = {
				// principal = workspaceId;
				// name = data.name;
				ref = workspace;
				members = [data.owner];
			};

			Map.set<Principal, Workspace>(_workspaces, phash, workspaceId, newWorkspace);
		};

		public func findByMember(member : Principal) : Workspaces {
			let workspaces = Map.filter<Principal, Workspace>(
				_workspaces,
				phash,
				func(key, value) {
					let index = Array.indexOf(member, value.members, Principal.equal);

					if (index == null) { return false };

					return true;
				},
			);

			return workspaces;
		};
	};
};
