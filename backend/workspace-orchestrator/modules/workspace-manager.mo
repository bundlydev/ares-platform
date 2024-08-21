// Base Modules
import Principal "mo:base/Principal";
import List "mo:base/List";
import Array "mo:base/Array";
import Error "mo:base/Error";
import Result "mo:base/Result";
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
import WorkspaceIam "../../workspace-iam/main";

import WorkspaceOrchestratorModels "../models";

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
		};
	};

	public class WorkspaceManagerService(
		_storage : WorkspaceOrchestratorModels.WorkspaceCollection,
		cyclesLedgerService : CyclesLedgerModule.CyclesLedgerService,
		accountManager : Principal,
	) {
		private let ic = actor ("aaaaa-aa") : IC.Service;

		public func getAll() : [WorkspaceOrchestratorModels.Workspace] {
			let workspaceIter = Map.vals<Principal, WorkspaceOrchestratorModels.Workspace>(_storage);
			let workspaceArray = Iter.toArray(workspaceIter);
			return workspaceArray;
		};

		public func getById(workspaceId : Principal) : ?WorkspaceOrchestratorModels.Workspace {
			return Map.get<Principal, WorkspaceOrchestratorModels.Workspace>(_storage, phash, workspaceId);
		};

		public func getAllByMemberId(memberId : Principal) : [WorkspaceOrchestratorModels.Workspace] {
			var workspaceList : List.List<WorkspaceOrchestratorModels.Workspace> = List.nil();

			for (workspace in Map.vals<Principal, WorkspaceOrchestratorModels.Workspace>(_storage)) {
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

					ignore Map.put<Principal, WorkspaceOrchestratorModels.Workspace>(_storage, phash, workspaceUpdated.wip, workspaceUpdated);
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

					ignore Map.put<Principal, WorkspaceOrchestratorModels.Workspace>(_storage, phash, workspaceUpdated.wip, workspaceUpdated);
				};
				case null throw Error.reject(WORKSPACE_NOT_FOUND);
			};
		};

		public func create(name : Text, creator : Principal) : async WorkspaceOrchestratorModels.Workspace {
			let iam = await createIamCanister(creator);

			// TODO: Generate a random principal
			let wip = Principal.fromActor(iam);

			let workspace : WorkspaceOrchestratorModels.Workspace = {
				wip;
				name;
				owner = creator;
				members = [];
				canisters = {
					iam = iam;
				};
			};

			ignore Map.put<Principal, WorkspaceOrchestratorModels.Workspace>(_storage, phash, workspace.wip, workspace);

			// Init Default IAM Access
			let adminPolicy = {
				pid = "AdministratorAccess";
				ptype = #managed;
				statements = [{
					effect = #allow;
					action = "*";
				}];
			};

			ignore await iam.create_policy(adminPolicy);

			let addRoleResult = await iam.create_role("Administrator", [adminPolicy.pid]);

			switch (addRoleResult) {
				case (#ok(role)) {
					ignore await iam.create_access(creator, role.rid, #user);

					return workspace;
				};
				case (#err(_error)) {
					// TODO: Handle error correctly
					throw Error.reject("Error");
				};
			};
		};

		public func createIamCanister(owner : Principal) : async WorkspaceIam.IamActorClass {
			// TODO: Validate if 113_846_199_230 is the correct amount and if it should be a constant
			Cycles.add<system>(113_846_199_230);

			let iam = await WorkspaceIam.IamActorClass(owner, accountManager);

			return iam;
		};

		public func delete(workspaceId : Principal, requester : Principal) : async ({ refundedCycles : Nat }) {
			let maybeWorkspace = getById(workspaceId);

			switch (maybeWorkspace) {
				case (?workspace) {
					let hasAccess = Principal.equal(workspace.owner, requester);

					if (not hasAccess) {
						throw Error.reject(UNAUTHORIZED);
					};

					let deleteIamCanisterResult = await deleteIamCanister(workspace.canisters.iam);

					switch (deleteIamCanisterResult) {
						case (#ok(iamResult)) {
							ignore Map.remove<Principal, WorkspaceOrchestratorModels.Workspace>(_storage, phash, workspaceId);

							let refundedCycles = iamResult.refundedCycles;

							let newCyclesEntry : CyclesLedgerModule.CycleTransaction = {
								amount = refundedCycles;
								recipient = workspace.owner;
								transactionDate = Time.now();
								transactionType = #deposit;
							};

							cyclesLedgerService.addTransaction(newCyclesEntry);

							return { refundedCycles };
						};
						case (_) {
							// TODO: Handle error correctly
							throw Error.reject("Error");
						};
					};
				};
				case null throw Error.reject(WORKSPACE_NOT_FOUND);
			};
		};

		type DeleteIamCanisterResultOk = {
			refundedCycles : Nat;
		};

		type DeleteIamCanisterResultErr = {
			#unauthorized;
		};

		type DeleteIamCanisterResult = Result.Result<DeleteIamCanisterResultOk, DeleteIamCanisterResultErr>;

		public func deleteIamCanister(iam : WorkspaceIam.IamActorClass) : async DeleteIamCanisterResult {
			let deletionResult = await iam.prepare_deletion();

			await ic.stop_canister({ canister_id = Principal.fromActor(iam) });
			await ic.delete_canister({ canister_id = Principal.fromActor(iam) });

			return deletionResult;
		};
	};
};
