// Base Modules
import Principal "mo:base/Principal";
import List "mo:base/List";
import Array "mo:base/Array";
import Error "mo:base/Error";
import Time "mo:base/Time";
import Cycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";

// Mops Modules
import Map "mo:map/Map";
import { phash } "mo:map/Map";
import IC "mo:ic";

// Custom Modules
import CyclesLedgerModule "./cycles-ledger";

// Actor Classes
import WorkspaceActor "../../workspace/main";

import Models "../models";
import Results "../results";

module WorkspaceManager {
	// Errors
	public let WORKSPACE_NOT_FOUND = "Workspace not found";
	public let UNAUTHORIZED = "Unauthorized";

	public type CreateWorkspaceResult = {
		wip : Principal;
		name : Text;
		members : [Principal];
		canisters : {
			main : Principal;
			iam : Principal;
			webhooks : Principal;
		};
	};

	public class WorkspaceManagerService(
		_storage : Models.WorkspaceCollection,
		cyclesLedgerService : CyclesLedgerModule.CyclesLedgerService,
	) {
		private let ic = actor ("aaaaa-aa") : IC.Service;

		public func getAll() : [Models.Workspace] {
			let workspaceIter = Map.vals<Principal, Models.Workspace>(_storage);
			let workspaceArray = Iter.toArray(workspaceIter);
			return workspaceArray;
		};

		public func getById(workspaceId : Principal) : ?Models.Workspace {
			return Map.get<Principal, Models.Workspace>(_storage, phash, workspaceId);
		};

		public func getAllByMemberId(memberId : Principal) : [Models.Workspace] {
			var workspaceList : List.List<Models.Workspace> = List.nil();

			for (workspace in Map.vals<Principal, Models.Workspace>(_storage)) {
				for (member in workspace.members.vals()) {
					if (Principal.equal(member, memberId)) {
						workspaceList := List.push(workspace, workspaceList);
					};
				};
			};

			let workspaceArray = List.toArray(workspaceList);

			return workspaceArray;
		};

		public func addMember(workspaceId : Principal, memberId : Principal) : async () {
			let maybeWorkspace = getById(workspaceId);

			switch (maybeWorkspace) {
				case (?workspace) {
					let members = Array.append(workspace.members, [memberId]);

					let workspaceUpdated = { workspace with members = members };

					ignore Map.put<Principal, Models.Workspace>(_storage, phash, workspaceUpdated.wip, workspaceUpdated);
				};
				case null throw Error.reject(WORKSPACE_NOT_FOUND);
			};
		};

		public func removeMember(workspaceId : Principal, memberId : Principal) : async () {
			let maybeWorkspace = getById(workspaceId);

			switch (maybeWorkspace) {
				case (?workspace) {
					let members = Array.filter<Principal>(
						workspace.members,
						func(member) {
							return not Principal.equal(member, memberId);
						},
					);

					let workspaceUpdated = { workspace with members = members };

					ignore Map.put<Principal, Models.Workspace>(_storage, phash, workspaceUpdated.wip, workspaceUpdated);
				};
				case null throw Error.reject(WORKSPACE_NOT_FOUND);
			};
		};

		public func create(name : Text, creator : Principal) : async Models.Workspace {
			let workspaceRef = await createWorkspaceCanister(creator);

			await workspaceRef.init();

			let workspace : Models.Workspace = {
				wip = Principal.fromActor(workspaceRef);
				ref = workspaceRef;
				name;
				owner = creator;
				members = [creator];
			};

			ignore Map.put<Principal, Models.Workspace>(_storage, phash, workspace.wip, workspace);

			return workspace;
		};

		private func createWorkspaceCanister(owner : Principal) : async WorkspaceActor.WorkspaceClass {
			// TODO: Validate if 113_846_199_230 is the correct amount and if it should be a constant
			Cycles.add<system>(113_846_199_230);

			let workpace = await WorkspaceActor.WorkspaceClass(owner);

			return workpace;
		};

		public func delete(workspaceId : Principal, requester : Principal) : async ({ refundedCycles : Nat }) {
			let maybeWorkspace = getById(workspaceId);

			switch (maybeWorkspace) {
				case null throw Error.reject(WORKSPACE_NOT_FOUND);
				case (?workspace) {
					let hasAccess = Principal.equal(workspace.owner, requester);

					if (not hasAccess) {
						throw Error.reject(UNAUTHORIZED);
					};

					let canister = workspace.ref;

					let deleteResult = await deleteCanister(canister);

					switch (deleteResult) {
						case (#err(_error)) {
							throw Error.reject("Error on delete canister");
						};
						case (#ok(result)) {
							let refundedCycles = result.refundedCycles;
							let newCyclesEntry : CyclesLedgerModule.CycleTransaction = {
								amount = refundedCycles;
								recipient = workspace.owner;
								transactionDate = Time.now();
								transactionType = #deposit;
							};

							cyclesLedgerService.addTransaction(newCyclesEntry);

							return { refundedCycles };
						};
					};
				};
			};
		};

		type DeleteCanisterRef = actor {
			prepare_deletion : shared () -> async Results.DeleteCanisterResult;
		};

		private func deleteCanister(canister : DeleteCanisterRef) : async Results.DeleteCanisterResult {
			let deletionResult = await canister.prepare_deletion();

			await ic.stop_canister({ canister_id = Principal.fromActor(canister) });
			await ic.delete_canister({ canister_id = Principal.fromActor(canister) });

			return deletionResult;
		};
	};
};
