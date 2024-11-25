// Base Modules
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Iter "mo:base/Iter";

// Mops Modules
import Map "mo:map/Map";
import { phash } "mo:map/Map";

import Models "./models";
import Types "./types";

module {
	public class WebhookService(_repository : Models.WebhookRepository) {
		public func getAll() : [Models.Webhook] {
			let webhookIter = Map.vals<Principal, Models.Webhook>(_repository);
			let webhookArray = Iter.toArray(webhookIter);

			return webhookArray;
		};

		public func register(principal : Principal, name : Text, creator : Principal) : Models.Webhook {
			let webhook = {
				ref = actor (Principal.toText(principal)) : Types.Subscriber;
				name = name;
				createdAt = Time.now();
				createdBy = creator;
			};

			ignore Map.put<Principal, Models.Webhook>(_repository, phash, principal, webhook);

			return webhook;
		};

		public func remove(principal : Principal) : () {
			ignore Map.remove<Principal, Models.Webhook>(_repository, phash, principal);
		};

		public func emit<T>(event : Types.Event) : async () {
			for (webhook in getAll().vals()) {
				ignore webhook.ref.callback(event);

				// TODO: Add a function to register failed webhooks

				// TODO: Add a function to save logs
			};
		};
	};
};
