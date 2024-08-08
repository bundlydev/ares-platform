// Base Modules
import Principal "mo:base/Principal";

// Mops Modules
import Map "mo:map/Map";
import { phash } "mo:map/Map";

module WebhookModule {
	public type MemberAddedEvent = {
		userId : Principal;
		roleId : Nat;
	};

	public type MemberRemovedEvent = {
		userId : Principal;
	};

	public type WebhookEvent = {
		#memberAdded : MemberAddedEvent;
		#memberRemoved : MemberRemovedEvent;
	};

	public type Listener = actor {
		webhook_handler : (event : WebhookEvent) -> ();
	};

	public type ListenerEntity = {
		canisterId : Principal;
	};

	public type WebhookListenerStorage = Map.Map<Principal, ListenerEntity>;

	public class WebhookService(_storage : WebhookListenerStorage) {
		public func register(listener : ListenerEntity) : () {
			Map.set(_storage, phash, listener.canisterId, listener);
		};

		public func emit(event : WebhookEvent) : async () {
			// TODO: Should be a broadcast to all listeners
			// TODO: Should I implement a retry mechanism?
			for (listener in Map.vals(_storage)) {
				let canister : Listener = actor (Principal.toText(listener.canisterId));
				canister.webhook_handler(event);
			};
		};
	};
};
