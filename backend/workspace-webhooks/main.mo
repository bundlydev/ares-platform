// Base Modules
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Cycles "mo:base/ExperimentalCycles";

// Mops Modules
import Map "mo:map/Map";
import { phash } "mo:map/Map";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import IC "mo:ic";

import WorkspaceOrchestratorTypes "../workspace-orchestrator/types";

// Workspace Iam Modules
import WorkspaceIam "../workspace-iam/main";

import Models "./models";
import Types "./types";
import { PERMISSION_LIST } "./permissions";

shared ({ caller = creator }) actor class WorkspaceWebhooksActorClass(owner : Principal, iam : Principal) = Self {
	// Actors
	private let ic = actor ("aaaaa-aa") : IC.Service;
	private stable let _iam = actor (Principal.toText(iam)) : WorkspaceIam.IamActorClass;

	// State
	private stable let _creator = creator;
	private stable let _owner = owner;
	private stable var _emitters : [Principal] = [];
	private stable var webhooks : Models.WebhookRepository = Map.new();

	public shared ({ caller }) func prepare_deletion() : async WorkspaceOrchestratorTypes.PrepareCanisterDeletionResult {
		if (not Principal.equal(caller, _creator)) {
			return #err(#unauthorized);
		};

		let balance : Nat = Cycles.balance();

		// TODO: Validate if 100_000_000_000 is the correct amount and if it should be a constant
		let cycles : Nat = balance - 100_000_000_000;

		if (cycles > 0) {
			Cycles.add<system>(cycles);
			await ic.deposit_cycles({ canister_id = _creator });

			return #ok({
				refundedCycles = cycles;
			});
		};

		#ok({
			refundedCycles = 0;
		});
	};

	public shared ({ caller }) func register_emitters(emitters : [Principal]) : async () {
		if (caller != _creator) return;

		_emitters := Array.append<Principal>(_emitters, emitters);
	};

	public shared composite query ({ caller }) func get_webhook_list() : async Types.GetWebhookListResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.GET_WEBHOOK_LIST.id)))) return #err(#unauthorized);

		let webhookIter = Map.vals(webhooks);
		let webhookArray = Iter.toArray(webhookIter);

		return #ok(webhookArray);
	};

	public shared ({ caller }) func register_webhook(data : Types.RegisterWebhookData) : async Types.RegisterWebhookResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.REGISTER_WEBHOOK.id)))) return #err(#unauthorized);

		let webhook = {
			ref = actor (Principal.toText(data.principal)) : Models.Subscriber;
			name = data.name;
			createdAt = Time.now();
			createdBy = caller;
		};

		ignore Map.put<Principal, Models.Webhook>(webhooks, phash, caller, webhook);

		return #ok();
	};

	public shared ({ caller }) func remove_webhook(principal : Principal) : async Types.RegisterWebhookResult {
		if (not (await _iam.verify_access(caller, #permission(PERMISSION_LIST.REMOVE_WEBHOOK.id)))) return #err(#unauthorized);

		ignore Map.remove<Principal, Models.Webhook>(webhooks, phash, principal);

		return #ok();
	};

	public shared ({ caller }) func notify(event : Models.CanisterEvents) : async () {
		switch (Array.find<Principal>(_emitters, func emitter = emitter == caller)) {
			case (null) return;
			case (_) {
				for (webhook in Map.vals(webhooks)) {
					Debug.print("Notifying webhook");
					Debug.print("Scope" # event.scope);
					Debug.print("ID: " # event.id);

					await webhook.ref.callback(event);

					// TODO: Add a function to register failed webhooks

					// TODO: Add a function to save logs
				};
			};

			// TODO: Add a function to retry failed webhooks
		};
	};
};
