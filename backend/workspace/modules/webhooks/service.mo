// Base Modules
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";

// Mops Modules
import Map "mo:map/Map";
import { phash } "mo:map/Map";

import Models "./models";

import CoreTypes "../core/types";

module {
	public class WebhookService(_repository : Models.WebhookRepository) {
		type Event<T> = CoreTypes.Event<T>;

		public func getAll() : [Models.Webhook] {
			let webhookIter = Map.vals<Principal, Models.Webhook>(_repository);
			let webhookArray = Iter.toArray(webhookIter);

			return webhookArray;
		};

		public func register(principal : Principal, name : Text, creator : Principal) : () {
			let webhook = {
				ref = actor (Principal.toText(principal)) : Models.Subscriber;
				name = name;
				createdAt = Time.now();
				createdBy = creator;
			};

			ignore Map.put<Principal, Models.Webhook>(_repository, phash, principal, webhook);
		};

		public func remove(principal : Principal) : () {
			ignore Map.remove<Principal, Models.Webhook>(_repository, phash, principal);
		};

		// public func emit(event : Models.CanisterEvents) : async () {
		public func emit<T>(event : CoreTypes.Event<T>) : async () {
			for (webhook in getAll().vals()) {
				Debug.print("Notifying webhook");
				Debug.print("Scope" # event.action);

				ignore webhook.ref.callback(event);

				// TODO: Add a function to register failed webhooks

				// TODO: Add a function to save logs
			};
		};
	};
};
