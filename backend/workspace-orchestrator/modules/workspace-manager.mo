// Base Modules
import Principal "mo:base/Principal";
import List "mo:base/List";
import Array "mo:base/Array";
import Error "mo:base/Error";
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
import WorkspaceIam "../../workspace-iam/main";
import WorkspaceUserManagement "../../workspace-user-management/main";

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
	) {
		private let ic = actor ("aaaaa-aa") : IC.Service;

		private func generatePrincipal() : async Principal {
			let randomBlob = await Random.blob();
			var array = Blob.toArray(randomBlob);
			array := Array.subArray<Nat8>(array, 0, 28);
			let newBlob = Blob.fromArray(array);

			return Principal.fromBlob(newBlob);
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
			let user_management = await createUserManagementCanister(creator, Principal.fromActor(iam));

			let wip = await generatePrincipal();

			let workspace : WorkspaceOrchestratorModels.Workspace = {
				wip;
				name;
				owner = creator;
				members = [];
				canisters = {
					iam = iam;
					user_management = user_management;
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

		public func createIamCanister(owner : Principal) : async WorkspaceIam.IamActorClass {
			// TODO: Validate if 113_846_199_230 is the correct amount and if it should be a constant
			Cycles.add<system>(113_846_199_230);

			let iam = await WorkspaceIam.IamActorClass(owner);

			return iam;
		};

		public func createUserManagementCanister(owner : Principal, iam : Principal) : async WorkspaceUserManagement.WorkspaceUserManagementActorClass {
			// TODO: Validate if 113_846_199_230 is the correct amount and if it should be a constant
			Cycles.add<system>(113_846_199_230);

			let userManagement = await WorkspaceUserManagement.WorkspaceUserManagementActorClass(owner, iam);

			return userManagement;
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
					let deleteUserManagementCanisterResult = await deleteUserManagementCanister(workspace.canisters.user_management);

					switch (deleteIamCanisterResult, deleteUserManagementCanisterResult) {
						case (#ok(iamResult), #ok(userManagementResult)) {
							ignore Map.remove<Principal, WorkspaceOrchestratorModels.Workspace>(_storage, phash, workspaceId);

							let refundedCycles = iamResult.refundedCycles + userManagementResult.refundedCycles;

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

		type DeleteUserManagementCanisterResultOk = {
			refundedCycles : Nat;
		};

		type DeleteUserManagementCanisterResultErr = {
			#unauthorized;
		};

		type DeleteUserManagementCanisterResult = Result.Result<DeleteUserManagementCanisterResultOk, DeleteUserManagementCanisterResultErr>;

		public func deleteUserManagementCanister(userManagement : WorkspaceUserManagement.WorkspaceUserManagementActorClass) : async DeleteUserManagementCanisterResult {
			let deletionResult = await userManagement.prepare_deletion();

			await ic.stop_canister({ canister_id = Principal.fromActor(userManagement) });
			await ic.delete_canister({ canister_id = Principal.fromActor(userManagement) });

			return deletionResult;
		};
	};
};
