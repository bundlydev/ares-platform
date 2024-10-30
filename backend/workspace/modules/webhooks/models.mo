// Mops Modules
import Time "mo:base/Time";
import Map "mo:map/Map";

import CoreTypes "../core/types";

module WebhooksModels {
	public type Subscriber = actor { callback : shared (event : CoreTypes.Event<Any>) -> async () };

	public type Webhook = {
		ref : Subscriber;
		name : Text;
		createdAt : Time.Time;
		createdBy : Principal;
	};

	// TODO: Get Events from every canister
	public type CanisterEvents = CoreTypes.Event<Any>;

	public type WebhookRepository = Map.Map<Principal, Webhook>;
};
