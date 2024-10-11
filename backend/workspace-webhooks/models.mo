// Mops Modules
import Time "mo:base/Time";
import Map "mo:map/Map";

module WebhooksModels {
	public type Subscriber = actor { callback : shared (event : WebhookEvent<Any>) -> async () };

	public type Webhook = {
		ref : Subscriber;
		name : Text;
		createdAt : Time.Time;
		createdBy : Principal;
	};

	public type WebhookEvent<T> = {
		scope : Text;
		id : Text;
		event : T;
	};

	// TODO: Get Events from every canister
	public type CanisterEvents = WebhookEvent<Any>;

	public type WebhookRepository = Map.Map<Principal, Webhook>;
};
