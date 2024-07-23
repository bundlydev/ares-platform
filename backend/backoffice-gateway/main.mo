import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Cycles "mo:base/ExperimentalCycles";
import Array "mo:base/Array";
import Text "mo:base/Text";

import Map "mo:map/Map";
import { phash } "mo:map/Map";
import TextValidator "mo:validators/Text";

import WorkspaceClass "../workspace/main";
import Types "./types";
import Models "./models";

actor {
	// Database
	stable let _profiles = Map.new<Principal, Models.Profile>();
	stable let _workspaces = Map.new<Principal, Models.Workspace>();

	public shared query ({ caller }) func getProfile() : async Types.GetProfileResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);

		let maybeProfile = Map.get(_profiles, phash, caller);

		switch maybeProfile {
			case (?profile) {
				#ok(profile);
			};
			case null {
				#err(#profileNotFound);
			};
		};
	};

	public shared ({ caller }) func createProfile(data : Types.CreateProfileData) : async Types.CreateProfileResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);
		if (Map.get(_profiles, phash, caller) != null) return #err(#principalAlreadyRegistered);

		// TODO: Should validations be done here or in the profile service?

		if (TextValidator.isEmpty(data.username)) {
			return #err(#requiredField("username"));
		} else if (TextValidator.isEmpty(data.email)) {
			return #err(#requiredField("email"));
		} else if (TextValidator.isEmpty(data.firstName)) {
			return #err(#requiredField("firstName"));
		} else if (TextValidator.isEmpty(data.lastName)) {
			return #err(#requiredField("lastName"));
		};

		for (profile in Map.vals(_profiles)) {
			if (profile.username == data.username) {
				return #err(#usernameAlreadyExists);
			};
		};

		let newProfile : Models.Profile = {
			username = data.username;
			firstName = data.firstName;
			lastName = data.lastName;
			email = data.email;
		};

		Map.set<Principal, Models.Profile>(_profiles, phash, caller, newProfile);

		#ok();
	};

	public shared query ({ caller }) func findProfilesByUsernameChunk(chunk : Text) : async Types.FindProfilesByUsernameChunkResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);
		if (Map.get(_profiles, phash, caller) == null) return #err(#profileNotFound);
		if (Text.size(chunk) < 3) return #err(#chunkTooShort);

		let matchedProfiles = Map.filter<Principal, Models.Profile>(
			_profiles,
			phash,
			func(key, value) {
				return Text.contains(value.username, #text chunk) and not Principal.equal(key, caller);
			},
		);

		let matchedProfilesArray = Iter.toArray(Map.entries(matchedProfiles));

		let preResult = Array.map<(Principal, Models.Profile), { id : Principal; username : Text }>(
			matchedProfilesArray,
			func(item) {
				return {
					id = item.0;
					username = item.1.username;
				};
			},
		);

		let maxResultLength = if (Array.size(preResult) < 10) Array.size(preResult) else 10;

		let result = Array.subArray(preResult, 0, maxResultLength);

		return #ok(result);
	};

	public shared query ({ caller }) func getMyWorkspaces() : async Types.GetMyWorkspacesResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);
		if (Map.get(_profiles, phash, caller) == null) return #err(#profileNotFound);

		let workspaceMap = Map.filter<Principal, Models.Workspace>(
			_workspaces,
			phash,
			func(key, value) {
				let index = Array.indexOf(caller, value.members, Principal.equal);

				if (index == null) { return false };

				return true;
			},
		);
		let workspaceIter = Map.vals(workspaceMap);
		let workspaces = Iter.toArray(workspaceIter);

		let result = Array.map<Models.Workspace, { id : Principal; members : [Principal] }>(
			workspaces,
			func item = {
				id = Principal.fromActor(item.ref);
				members = item.members;
			},
		);

		return #ok(result);
	};

	public shared ({ caller }) func createWorkspace(data : Types.CreateWorkspaceData) : async Types.CreateWorkspaceResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);
		if (Map.get(_profiles, phash, caller) == null) return #err(#profileNotFound);

		if (TextValidator.isEmpty(data.name)) {
			return #err(#requiredField("name"));
		};

		Cycles.add(113_846_199_230);

		let workspace = await WorkspaceClass.WorkspaceClass(data.name, caller);
		let workspaceId = Principal.fromActor(workspace);

		let newWorkspace : Models.Workspace = {
			ref = workspace;
			members = [caller];
		};

		Map.set<Principal, Models.Workspace>(_workspaces, phash, workspaceId, newWorkspace);

		#ok(());
	};

	public shared composite query ({ caller }) func getWorkspaceInfo(workspaceId : Principal) : async Types.GetWorkspaceInfoResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);
		if (Map.get(_profiles, phash, caller) == null) return #err(#profileNotFound);

		let workspace = Map.get(_workspaces, phash, workspaceId);

		switch workspace {
			case (null) { #err(#workspaceNotFound) };
			case (?wp) {
				let memberId = Array.find<Principal>(wp.members, func mem = Principal.equal(mem, caller));

				switch memberId {
					case (null) #err(#unauthorized);
					case (_) {
						let result = await wp.ref.getInfo();
						switch result {
							case (#ok(info)) {
								#ok(info);
							};
							case (_) return result;
						};
					};
				};
			};
		};
	};

	public shared ({ caller }) func addWorkspaceMember(workspaceId : Principal, userId : Principal) : async Types.AddWorkspaceMemberResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);
		if (Map.get(_profiles, phash, caller) == null) return #err(#profileNotFound);

		let workspace = Map.get(_workspaces, phash, workspaceId);

		switch workspace {
			case (null) #err(#workspaceNotFound);
			case (?wp) {
				let memberId = Array.find<Principal>(wp.members, func mem = Principal.equal(mem, caller));

				switch memberId {
					case (null) #err(#unauthorized);
					case (_) {
						let result = await wp.ref.addMember(userId, 2);

						switch result {
							case (#ok()) {
								let members : [Principal] = Array.append<Principal>(wp.members, [userId]);
								let workspaceId : Principal = Principal.fromActor(wp.ref);

								let workspaceUpdate : Models.Workspace = {
									ref = wp.ref;
									members;
								};

								Map.set<Principal, Models.Workspace>(_workspaces, phash, workspaceId, workspaceUpdate);

								#ok();
							};
							case (_) return result;
						};
					};
				};
			};
		};
	};

	public shared ({ caller }) func removeWorkspaceMember(workspaceId : Principal, userId : Principal) : async Types.RemoveWorkspaceMemberResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);
		if (Map.get(_profiles, phash, caller) == null) return #err(#profileNotFound);

		let workspace = Map.get(_workspaces, phash, workspaceId);

		switch workspace {
			case (null) #err(#workspaceNotFound);
			case (?wp) {
				let memberId = Array.find<Principal>(wp.members, func mem = Principal.equal(mem, caller));

				switch memberId {
					case (null) #err(#unauthorized);
					case (_) {
						let result = await wp.ref.removeMember(userId);

						switch result {
							case (#ok()) {
								let members : [Principal] = Array.filter<Principal>(wp.members, func mem = not Principal.equal(mem, userId));
								let workspaceId : Principal = Principal.fromActor(wp.ref);

								let workspaceUpdate : Models.Workspace = {
									ref = wp.ref;
									members;
								};

								Map.set<Principal, Models.Workspace>(_workspaces, phash, workspaceId, workspaceUpdate);

								#ok();
							};
							case (_) return result;
						};
					};
				};
			};
		};
	};
};
