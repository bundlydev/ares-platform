// Base Modules
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Cycles "mo:base/ExperimentalCycles";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Time "mo:base/Time";
import List "mo:base/List";

// Mops Modules
import Map "mo:map/Map";
import { phash } "mo:map/Map";
import IC "mo:ic";

// Custom Modules
import TextValidator "mo:validators/Text";

// External Modules
import WebhookModule "../workspace/modules/webhook";
import WorkspaceClass "../workspace/main";

// Local Modules
import CyclesLedgerModule "./modules/cycles-ledger";

import Types "./types";
import Models "./models";

actor BackofficeGateway {
	// Database
	stable let _profileStorage: Models.ProfileStorage = Map.new<Principal, Models.ProfileEntity>();
	stable let _workspaceStorate: Models.WorkspaceStorage = Map.new<Principal, Models.WorkspaceEntity>();
	stable var _cyclesLedgerStorage: CyclesLedgerModule.CyclesLedgerStorage = List.nil();

	// Services
	private let ic = actor("aaaaa-aa") : IC.Service;
	private let cyclesLedgerService = CyclesLedgerModule.CyclesLedgerService(_cyclesLedgerStorage);

	private func getProfile(profileId: Principal): ?Models.ProfileEntity {
		return Map.get(_profileStorage, phash, profileId);
	};

	private func getWorkspace(workspaceId: Principal): ?Models.WorkspaceEntity {
		return Map.get(_workspaceStorate, phash, workspaceId);
	};

	public shared query func getCanisterBalance(): async Nat {
		// TODO: Add security check to prevent unauthorized access
		return Cycles.balance();
	};

	public shared query func getCanisterAvailableBalance(): async Nat {
		// TODO: Add security check to prevent unauthorized access
		let totalBalance : Nat = Cycles.balance();
		let availableBalance : Nat = totalBalance - cyclesLedgerService.getTotalBalance();

		return availableBalance;
	};

	public shared query ({ caller }) func getProfileById(profileId: Principal): async Types.GetProfileByIdResult {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);
		// TODO: Should I add extra security check to prevent unauthorized access to other profiles?

		let maybeProfile = getProfile(profileId);

		switch maybeProfile {
			case (?profile) #ok(profile);
			case null #err(#profileNotFound);
		};
	};

	public shared query ({ caller }) func getMyProfile() : async Types.GetProfileResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);

		let maybeProfile = getProfile(caller);

		switch maybeProfile {
			case (?profile) #ok(profile);
			case null #err(#profileNotFound);
		};
	};

	public shared ({ caller }) func createProfile(data : Types.CreateProfileData) : async Types.CreateProfileResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);
		if (getProfile(caller) != null) return #err(#principalAlreadyRegistered);

		if (TextValidator.isEmpty(data.username)) {
		// TODO: Validate username with regex ^[a-zA-Z0-9_]{5,15}$
			return #err(#requiredField("username"));
		} else if (TextValidator.isEmpty(data.email)) {
			// TODO: Validate email with regex ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
			return #err(#requiredField("email"));
		} else if (TextValidator.isEmpty(data.firstName)) {
			// TODO: Validate first name with regex /^[A-Za-zÀ-ÿ]+([-'\s][A-Za-zÀ-ÿ]+)*$/
			return #err(#requiredField("firstName"));
		} else if (TextValidator.isEmpty(data.lastName)) {
			// TODO: Validate last name with regex /^[A-Za-zÀ-ÿ]+([-'\s][A-Za-zÀ-ÿ]+)*$/
			return #err(#requiredField("lastName"));
		};

		for (profile in Map.vals(_profileStorage)) {
			if (profile.username == data.username) {
				return #err(#usernameAlreadyExists);
			};

			if (profile.email == data.email) {
				return #err(#emailAlreadyExists);
			};
		};

		let newProfile : Models.ProfileEntity = {
			username = data.username;
			firstName = data.firstName;
			lastName = data.lastName;
			email = data.email;
		};

		Map.set<Principal, Models.ProfileEntity>(_profileStorage, phash, caller, newProfile);

		#ok();
	};

	public shared query ({ caller }) func findProfilesByUsernameChunk(chunk : Text) : async Types.FindProfilesByUsernameChunkResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);
		if (getProfile(caller) == null) return #err(#profileNotFound);
		if (Text.size(chunk) < 3) return #err(#chunkTooShort);

		let matchedProfiles = Map.filter<Principal, Models.ProfileEntity>(
			_profileStorage,
			phash,
			func(key, value) {
				return Text.contains(value.username, #text chunk) and not Principal.equal(key, caller);
			},
		);

		let matchedProfilesArray = Iter.toArray(Map.entries(matchedProfiles));

		let preResult = Array.map<(Principal, Models.ProfileEntity), { id : Principal; username : Text }>(
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

	public shared query ({caller}) func getMyBalance(): async Types.GetMyBalanceResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);
		if (getProfile(caller) == null) return #err(#profileNotFound);

		let balance = cyclesLedgerService.getUserBalance(caller);

		#ok({balance});
	};

	public shared composite query ({ caller }) func getMyWorkspaces() : async Types.GetMyWorkspacesResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);
		if (getProfile(caller) == null) return #err(#profileNotFound);

		let workspaceMap = Map.filter<Principal, Models.WorkspaceEntity>(
			_workspaceStorate,
			phash,
			func(key, value) {
				let index = Array.indexOf(caller, value.members, Principal.equal);

				if (index == null) { return false };

				return true;
			},
		);
		let workspaceIter = Map.vals(workspaceMap);

		var workspaceList: List.List<Types.GetMyWorkspacesResponseOkItem> = List.nil();

		for (workspace in workspaceIter) {
			let info = {
				id = Principal.fromActor(workspace.ref);
				name = await workspace.ref.getName();
			};

			workspaceList := List.push<Types.GetMyWorkspacesResponseOkItem>(info, workspaceList);
		};

		return #ok(List.toArray(workspaceList));
	};

	public shared ({ caller }) func createWorkspace(data : Types.CreateWorkspaceData) : async Types.CreateWorkspaceResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);
		if (getProfile(caller) == null) return #err(#profileNotFound);

		if (TextValidator.isEmpty(data.name)) {
			return #err(#requiredField("name"));
		};

		// TODO: Validate if 113_846_199_230 is the correct amount and if it should be a constant
		Cycles.add(113_846_199_230);

		let workspace = await WorkspaceClass.WorkspaceActorClass(data.name);
		let workspaceId = Principal.fromActor(workspace);
		ignore await workspace.addWebhookListener(Principal.fromActor(BackofficeGateway));
		ignore await workspace.addFirstOwner(caller);

		let newWorkspace : Models.WorkspaceEntity = {
			ref = workspace;
			members = [];
		};

		Map.set<Principal, Models.WorkspaceEntity>(_workspaceStorate, phash, workspaceId, newWorkspace);

		#ok({ workspaceId });
	};

	public shared ({caller}) func deleteWorkspace(workspaceId : Principal) : async Types.DeleteWorkspaceResponse {
		if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);
		if (getProfile(caller) == null) return #err(#profileNotFound);

		let maybeWorkspace = Map.get(_workspaceStorate, phash, workspaceId);

		switch maybeWorkspace {
			case null #err(#workspaceNotFound);
			case (?workspace) {
				let onDeleteResult = await workspace.ref.onDelete(caller);

				switch onDeleteResult {
					case (#ok(result)) {
						await ic.stop_canister({canister_id = Principal.fromActor(workspace.ref)});
						await ic.delete_canister({canister_id = Principal.fromActor(workspace.ref)});

						ignore Map.remove<Principal, Models.WorkspaceEntity>(_workspaceStorate, phash, workspaceId);

						let newCyclesEntry: CyclesLedgerModule.CycleTransaction = {
							amount = result.refundedCycles;
							recipient = caller;
							transactionDate = Time.now();
							transactionType = #deposit;
						};

						cyclesLedgerService.addTransaction(newCyclesEntry);

						#ok({ refundedCycles = result.refundedCycles });
					};
					case (#err(_error)) #err(_error);
				};
			};
		};
	};

	private func _addWorkspaceMember(workspace : Models.WorkspaceEntity, newMember : WebhookModule.MemberAddedEvent) {
		let members : [Principal] = Array.append<Principal>(workspace.members, [newMember.userId]);

		let workspaceUpdate : Models.WorkspaceEntity = {
			ref = workspace.ref;
			members;
		};

		let workspaceId = Principal.fromActor(workspace.ref);

		Map.set<Principal, Models.WorkspaceEntity>(_workspaceStorate, phash, workspaceId, workspaceUpdate);
	};

	private func _removeWorkspaceMember(workspace : Models.WorkspaceEntity, removedMember : WebhookModule.MemberRemovedEvent) {
		let members : [Principal] = Array.filter<Principal>(workspace.members, func mem = not Principal.equal(mem, removedMember.userId));

		let workspaceUpdate : Models.WorkspaceEntity = {
			ref = workspace.ref;
			members;
		};

		let workspaceId = Principal.fromActor(workspace.ref);

		Map.set<Principal, Models.WorkspaceEntity>(_workspaceStorate, phash, workspaceId, workspaceUpdate);
	};

	public shared ({caller}) func webhook_handler(event : WebhookModule.WebhookEvent): async Types.WebhookHandlerResult {
		if (Principal.isAnonymous(caller)) return #err(#unauthorized);

		let maybeWorksace = getWorkspace(caller);

		switch maybeWorksace {
			case (?workspace) {
				switch event {
					case (#memberAdded(newMember)) {
						_addWorkspaceMember(workspace, newMember);

						#ok();
					};
					case (#memberRemoved(removedMember)) {
						_removeWorkspaceMember(workspace, removedMember);

						#ok();
					};
				};
			};
			case null #err(#unauthorized);
		};
	}
};
