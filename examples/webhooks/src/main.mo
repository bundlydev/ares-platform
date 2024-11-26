import WebhookTypes "../../../backend/workspace/modules/webhooks/types";

import Debug "mo:base/Debug";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Iter "mo:base/Iter";

actor {
	type EventTrack = {
		data : WebhookTypes.Event;
		timestamp : Time.Time;
	};

	var nextEventId = 0;

	func natHash(n : Nat) : Hash.Hash {
		Text.hash(Nat.toText(n));
	};

	let eventTracker = HashMap.HashMap<Nat, EventTrack>(5, Nat.equal, natHash);

	private func iamEventHandler(scope : WebhookTypes.IamEvent) : () {
		Debug.print("Module: IAM");

		switch (scope) {
			case (#policy(action)) {
				Debug.print("Scope: Policy");

				switch (action) {
					case (#created(_payload)) {
						Debug.print("Action: Created");
					};
					case (#deleted(_payload)) {};
				};
			};
			case (#role(action)) {
				Debug.print("Scope: Role");

				switch (action) {
					case (#created(_payload)) {
						Debug.print("Action: Created");
					};
					case (#deleted(_payload)) {
						Debug.print("Action: Deleted");
					};
					case (#policyAdded(_payload)) {
						Debug.print("Action: Policy Added");
					};
					case (#policyRemoved(_payload)) {
						Debug.print("Action: Policy Removed");
					};
				};
			};
			case (#access(action)) {
				Debug.print("Scope: Access");

				switch (action) {
					case (#created(_payload)) {
						Debug.print("Action: Created");
					};
					case (#deleted(_payload)) {
						Debug.print("Action: Deleted");
					};
					case (#roleChanged(_payload)) {
						Debug.print("Action: Role Changed");
					};
				};
			};
		};
	};

	private func userEventHandler(scope : WebhookTypes.UserEvent) : () {
		Debug.print("Module: User");

		switch (scope) {
			case (#permission(action)) {
				Debug.print("Scope: Permission");

				switch (action) {
					case (#created(_payload)) {
						Debug.print("Action: Created");
					};
					case (#deleted(_payload)) {
						Debug.print("Action: Deleted");
					};
				};
			};
			case (#role(action)) {
				Debug.print("Scope: Role");

				switch (action) {
					case (#created(_payload)) {
						Debug.print("Action: Created");
					};
					case (#deleted(_payload)) {
						Debug.print("Action: Deleted");
					};
					case (#permissionAdded(_payload)) {
						Debug.print("Action: Permission Added");
					};
					case (#permissionRemoved(_payload)) {
						Debug.print("Action: Permission Removed");
					};
				};
			};
			case (#access(action)) {
				Debug.print("Scope: Access");

				switch (action) {
					case (#created(_payload)) {
						Debug.print("Action: Created");
					};
					case (#deleted(_payload)) {
						Debug.print("Action: Deleted");
					};
					case (#statusChanged(_payload)) {
						Debug.print("Action: Status Changed");
					};
					case (#roleAdded(_payload)) {
						Debug.print("Action: Role Added");
					};
					case (#roleRemoved(_payload)) {
						Debug.print("Action: Role Removed");
					};
					case (#permissionAdded(_payload)) {
						Debug.print("Action: Permission Added");
					};
					case (#permissionRemoved(_payload)) {
						Debug.print("Action: Permission Removed");
					};
				};
			};
		};
	};

	private func webhookEventHandler(scope : WebhookTypes.WebhookEvent) : () {
		Debug.print("Module: Webhook");

		switch (scope) {
			case (#webhook(action)) {
				Debug.print("Scope: Webhook");

				switch (action) {
					case (#registered(_payload)) {
						Debug.print("Action: Registered");
					};
					case (#removed(_payload)) {
						Debug.print("Action: Removed");
					};
				};
			};
		};
	};

	public shared func callback(event : WebhookTypes.Event) : () {
		Debug.print("--------------");
		Debug.print("Event received");

		eventTracker.put(nextEventId, { data = event; timestamp = Time.now() });
		nextEventId += 1;

		switch (event) {
			case (#iam(scope)) {
				iamEventHandler(scope);
			};
			case (#user(scope)) {
				userEventHandler(scope);
			};
			case (#webhook(scope)) {
				webhookEventHandler(scope);
			};
		};
		Debug.print("--------------");
	};

	public shared query func getEvents() : async [EventTrack] {
		let iter = eventTracker.vals();
		let arr = Iter.toArray(iter);

		return arr;
	};
};
