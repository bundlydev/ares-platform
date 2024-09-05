// Base Modules
import Principal "mo:base/Principal";
import Cycles "mo:base/ExperimentalCycles";
import Array "mo:base/Array";

// Mops Modules
import Map "mo:map/Map";

// Custom Modules
import TextValidator "mo:validators/Text";

// Local Modules
// TODO: CyclesLedger should be a separate canister?
import CyclesLedgerModule "./modules/cycles-ledger";
import WorkspaceManager "./modules/workspace-manager";

import WorkspaceOrchestratorEvents "./events";
import WorkspaceOrchestratorModels "./models";
import WorkspaceOrchestratorTypes "./types";

actor WorkspaceOrchestrator {
	// Database
	stable let _workspaces : WorkspaceOrchestratorModels.WorkspaceCollection = Map.new<Principal, WorkspaceOrchestratorModels.Workspace>();
	stable var _cyclesLedger : CyclesLedgerModule.CyclesLedgerStorage = Map.new<Nat, CyclesLedgerModule.CycleTransaction>();

	// Services
	private let cyclesLedgerService = CyclesLedgerModule.CyclesLedgerService(_cyclesLedger);
	private let workspaceManagerService = WorkspaceManager.WorkspaceManagerService(_workspaces, cyclesLedgerService);

	public shared query func get_canister_balance() : async Nat {
		// TODO: Add security check to prevent unauthorized access
		return Cycles.balance();
	};

	public shared query func get_canister_available_balance() : async Nat {
		// TODO: Add security check to prevent unauthorized access
		let totalBalance : Nat = Cycles.balance();
		let availableBalance : Nat = totalBalance - cyclesLedgerService.getTotalBalance();

		return availableBalance;
	};

	public shared composite query ({ caller }) func get_my_balance() : async WorkspaceOrchestratorTypes.GetMyBalanceResponse {
		if (Principal.isAnonymous(caller)) return #err(#unauthorized);

		let balance = cyclesLedgerService.getUserBalance(caller);

		#ok({ balance });
	};

	public shared composite query ({ caller }) func get_my_workspaces() : async WorkspaceOrchestratorTypes.GetMyWorkspacesResponse {
		if (Principal.isAnonymous(caller)) return #err(#unauthorized);

		let workspaces = workspaceManagerService.getAllByMemberId(caller);

		let result = Array.map<WorkspaceOrchestratorModels.Workspace, WorkspaceOrchestratorTypes.GetMyWorkspacesResponseOkItem>(
			workspaces,
			func(workspace) {
				return {
					wip = workspace.wip;
					name = workspace.name;
				};
			},
		);

		return #ok(result);
	};

	public shared query ({ caller }) func get_workspace_info(wip : Principal) : async WorkspaceOrchestratorTypes.GetWorkspaceInfoResult {
		if (Principal.isAnonymous(caller)) return #err(#unauthorized);

		switch (workspaceManagerService.getById(wip)) {
			case (?workspace) {
				let member = Array.find<Principal>(
					workspace.members,
					func(member) = Principal.equal(member, caller),
				);

				if (member == null) return #err(#unauthorized);

				let result = {
					wip = workspace.wip;
					name = workspace.name;
					owner = workspace.owner;
					members = workspace.members;
					canisters = {
						iam = Principal.fromActor(workspace.canisters.iam);
						user_management = Principal.fromActor(workspace.canisters.access_management);
					};
				};

				return #ok(result);
			};
			case (null) #err(#workspaceNotFound);
		};
	};

	public shared ({ caller }) func create_workspace(data : WorkspaceOrchestratorTypes.CreateWorkspaceData) : async WorkspaceOrchestratorTypes.CreateWorkspaceResponse {
		if (Principal.isAnonymous(caller)) return #err(#unauthorized);
		// TODO: Validate if the account exists

		if (TextValidator.isEmpty(data.name)) {
			return #err(#requiredField("name"));
		};

		let workspace = await workspaceManagerService.create(data.name, caller);

		let result = {
			// TODO: Change how the workspace id is generated
			// TODO: Add created_at field
			wip = workspace.wip;
			name = workspace.name;
			owner = workspace.owner;
			members = workspace.members;
			canisters = {
				iam = Principal.fromActor(workspace.canisters.iam);
				user_management = Principal.fromActor(workspace.canisters.access_management);
			};
		};

		#ok(result);
	};

	public shared ({ caller }) func delete_workspace(wip : Principal) : async WorkspaceOrchestratorTypes.DeleteWorkspaceResponse {
		if (Principal.isAnonymous(caller)) return #err(#unauthorized);
		// TODO: Validate if the account exists

		try {
			let deleteResult = await workspaceManagerService.delete(wip, caller);

			#ok(deleteResult);
		} catch (_error) {
			// TODO: Handle error
			return #err(#unauthorized);
		};
	};

	public shared ({ caller }) func webhook_receiver(event : WorkspaceOrchestratorEvents.EventVariants) {
		if (Principal.isAnonymous(caller)) return;

		let maybeWorkspace = Array.find<WorkspaceOrchestratorModels.Workspace>(
			workspaceManagerService.getAll(),
			func workspace = Principal.equal(workspace.wip, caller),
		);

		if (maybeWorkspace == null) return;

		switch (event) {
			case (#WorkspaceIam(event)) {
				switch (event) {
					case (#AccessCreated(data)) {
						if (data.itype == #user) {
							await workspaceManagerService.addMember(caller, data.identity);
						};
					};
					case (#AccessRemoved(data)) {
						if (data.itype == #user) {
							await workspaceManagerService.removeMember(caller, data.identity);
						};
					};
				};
			};
		};
	};
};
