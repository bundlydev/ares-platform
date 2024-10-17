// Base Modules
import Principal "mo:base/Principal";
import List "mo:base/List";
import Array "mo:base/Array";
import Error "mo:base/Error";
// TODO: Should I remove Result and use throw?
import Result "mo:base/Result";
import Time "mo:base/Time";
import Cycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";
import Random "mo:base/Random";
import Blob "mo:base/Blob";

// Mops Modules
import Map "mo:map/Map";
import { phash } "mo:map/Map";
import IC "mo:ic";

// Custom Modules
import CyclesLedgerModule "./cycles-ledger";

// Actor Classes
import WorkspaceActor "../../workspace/main";
import WorkspaceIam "../../workspace-iam/main";
import WorkspaceUsers "../../workspace-users/main";
import WorkspaceWebhooks "../../workspace-webhooks/main";

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
			webhooks : Principal;
		};
	};

	public class WorkspaceManagerService(
		_storage : WorkspaceOrchestratorModels.WorkspaceCollection,
		cyclesLedgerService : CyclesLedgerModule.CyclesLedgerService,
	) {
		private let ic = actor ("aaaaa-aa") : IC.Service;

		private func generatePrincipal() : async Principal {
			var b = await Random.blob();
			var array = Blob.toArray(b);
			array := Array.subArray<Nat8>(array, 0, 10);
			b := Blob.fromArray(array);
			Principal.fromBlob(b);
		};

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

		public func getWorkspaceByChild(principal : Principal) : ?WorkspaceOrchestratorModels.Workspace {
			return Array.find<WorkspaceOrchestratorModels.Workspace>(
				getAll(),
				func workspace = Principal.equal(Principal.fromActor(workspace.canisters.iam), principal) or
				Principal.equal(Principal.fromActor(workspace.canisters.users), principal) or
				Principal.equal(Principal.fromActor(workspace.canisters.webhooks), principal),
			);
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
			let workspaceRef = await createWorkspaceCanister(creator);
			let iam = await createIamCanister(creator);
			let users = await createUsersCanister(creator, Principal.fromActor(iam));
			let webhooks = await createWebhooksCanister(creator, Principal.fromActor(iam));

			await workspaceRef.init();

			let wip = await generatePrincipal();

			let workspace : WorkspaceOrchestratorModels.Workspace = {
				wip;
				ref = workspaceRef;
				name;
				owner = creator;
				members = [];
				canisters = {
					iam;
					users;
					webhooks;
				};
			};

			ignore Map.put<Principal, WorkspaceOrchestratorModels.Workspace>(_storage, phash, workspace.wip, workspace);

			// Init Default IAM Access
			let adminPolicy = {
				pid = "AdministratorAccess";
				ptype = #managed;
				statements = [{
					effect = #allow;
					action = #all;
				}];
			};

			ignore await iam.create_policy(adminPolicy);

			let adminRoleData = {
				name = "Administrator";
				description = "Grant full access to the workspace";
				policies = [adminPolicy.pid];
			};

			let addRoleResult = await iam.create_role(adminRoleData);

			switch (addRoleResult) {
				case (#ok(role)) {
					let newAccess = {
						identity = creator;
						roleId = role.rid;
						itype = #user;
					};

					ignore await iam.create_access(newAccess);

					return workspace;
				};
				case (#err(_error)) {
					// TODO: Handle error correctly
					throw Error.reject("Error");
				};
			};
		};

		private func createWorkspaceCanister(owner : Principal) : async WorkspaceActor.WorkspaceClass {
			// TODO: Validate if 113_846_199_230 is the correct amount and if it should be a constant
			Cycles.add<system>(113_846_199_230);

			let workpace = await WorkspaceActor.WorkspaceClass(owner);

			return workpace;
		};

		private func createIamCanister(owner : Principal) : async WorkspaceIam.IamActorClass {
			// TODO: Validate if 113_846_199_230 is the correct amount and if it should be a constant
			Cycles.add<system>(113_846_199_230);

			let iam = await WorkspaceIam.IamActorClass(owner);

			return iam;
		};

		private func createUsersCanister(owner : Principal, iam : Principal) : async WorkspaceUsers.WorkspaceUsersActorClass {
			// TODO: Validate if 113_846_199_230 is the correct amount and if it should be a constant
			Cycles.add<system>(113_846_199_230);

			let users = await WorkspaceUsers.WorkspaceUsersActorClass(owner, iam);

			return users;
		};

		private func createWebhooksCanister(owner : Principal, iam : Principal) : async WorkspaceWebhooks.WorkspaceWebhooksActorClass {
			// TODO: Validate if 113_846_199_230 is the correct amount and if it should be a constant
			Cycles.add<system>(113_846_199_230);

			let webhooks = await WorkspaceWebhooks.WorkspaceWebhooksActorClass(owner, iam);

			return webhooks;
		};

		public func delete(workspaceId : Principal, requester : Principal) : async ({ refundedCycles : Nat }) {
			let maybeWorkspace = getById(workspaceId);

			switch (maybeWorkspace) {
				case (?workspace) {
					let hasAccess = Principal.equal(workspace.owner, requester);

					if (not hasAccess) {
						throw Error.reject(UNAUTHORIZED);
					};

					let deleteIamCanisterResult = await deleteCanister(workspace.canisters.iam);
					let deleteUsersCanisterResult = await deleteCanister(workspace.canisters.users);
					let deleteWebhooksCanisterResult = await deleteCanister(workspace.canisters.webhooks);

					switch (deleteIamCanisterResult, deleteUsersCanisterResult, deleteWebhooksCanisterResult) {
						case (#ok(iamResult), #ok(usersResult), #ok(webhooksResult)) {
							ignore Map.remove<Principal, WorkspaceOrchestratorModels.Workspace>(_storage, phash, workspaceId);

							let refundedCycles = iamResult.refundedCycles + usersResult.refundedCycles + webhooksResult.refundedCycles;

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

		type DeleteCanisterRef = actor {
			prepare_deletion : shared () -> async DeleteCanisterResult;
		};

		type DeleteCanisterOk = {
			refundedCycles : Nat;
		};

		type DeleteCanisterErr = {
			#unauthorized;
		};

		type DeleteCanisterResult = Result.Result<DeleteCanisterOk, DeleteCanisterErr>;

		private func deleteCanister(canister : DeleteCanisterRef) : async DeleteCanisterResult {
			let deletionResult = await canister.prepare_deletion();

			await ic.stop_canister({ canister_id = Principal.fromActor(canister) });
			await ic.delete_canister({ canister_id = Principal.fromActor(canister) });

			return deletionResult;
		};
	};
};
