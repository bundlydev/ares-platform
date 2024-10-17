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

// import Events "./events";
import Models "./models";
import Results "./results";

actor WorkspaceOrchestrator {
	// Database
	stable let _workspaces : Models.WorkspaceCollection = Map.new<Principal, Models.Workspace>();
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

	public shared composite query ({ caller }) func get_my_balance() : async Results.GetMyBalanceResult {
		if (Principal.isAnonymous(caller)) return #err(#unauthorized);

		let balance = cyclesLedgerService.getUserBalance(caller);

		#ok({ balance });
	};

	public shared composite query ({ caller }) func get_my_workspaces() : async Results.GetMyWorkspacesResult {
		if (Principal.isAnonymous(caller)) return #err(#unauthorized);

		let workspaces = workspaceManagerService.getAllByMemberId(caller);

		let result = Array.map<Models.Workspace, Results.GetMyWorkspacesResultOkItem>(
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

	public shared query ({ caller }) func get_workspace_info(wip : Principal) : async Results.GetWorkspaceInfoResult {
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
					ref = Principal.fromActor(workspace.ref);
					name = workspace.name;
					owner = workspace.owner;
					members = workspace.members;
					canisters = {
						iam = Principal.fromActor(workspace.canisters.iam);
						users = Principal.fromActor(workspace.canisters.users);
						webhooks = Principal.fromActor(workspace.canisters.webhooks);
					};
				};

				return #ok(result);
			};
			case (null) #err(#workspaceNotFound);
		};
	};

	public shared ({ caller }) func create_workspace(data : Results.CreateWorkspaceData) : async Results.CreateWorkspaceResult {
		if (Principal.isAnonymous(caller)) return #err(#unauthorized);
		// TODO: Only users with account and cycles should be able to create a workspace

		if (TextValidator.isEmpty(data.name)) {
			return #err(#requiredField("name"));
		};

		let workspace = await workspaceManagerService.create(data.name, caller);

		let result = {
			wip = workspace.wip;
			ref = Principal.fromActor(workspace.ref);
			name = workspace.name;
			owner = workspace.owner;
			members = workspace.members;
			canisters = {
				iam = Principal.fromActor(workspace.canisters.iam);
				users = Principal.fromActor(workspace.canisters.users);
				webhooks = Principal.fromActor(workspace.canisters.webhooks);
			};
		};

		#ok(result);
	};

	public shared ({ caller }) func delete_workspace(wip : Principal) : async Results.DeleteWorkspaceResult {
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

	public shared ({ caller }) func add_workspace_member(userId : Principal) : async () {
		switch (workspaceManagerService.getWorkspaceByChild(caller)) {
			case (?workspace) {
				await workspaceManagerService.addMember(workspace.wip, userId);
			};
			// TODO: Return unauthorized error
			case (null) return;
		};
	};

	public shared ({ caller }) func remove_workspace_member(userId : Principal) : async () {
		switch (workspaceManagerService.getWorkspaceByChild(caller)) {
			case (?workspace) {
				await workspaceManagerService.removeMember(workspace.wip, userId);
			};
			// TODO: Return unauthorized error
			case (null) return;
		};
	};
};
