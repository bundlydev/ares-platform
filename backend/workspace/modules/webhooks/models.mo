// Mops Modules
import Time "mo:base/Time";
import Map "mo:map/Map";

import Types "./types";

module WebhooksModels {
	public type Webhook = {
		ref : Types.Subscriber;
		name : Text;
		createdAt : Time.Time;
		createdBy : Principal;
	};

	public type WebhookRepository = Map.Map<Principal, Webhook>;
};
