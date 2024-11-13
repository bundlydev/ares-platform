import Time "mo:base/Time";

import CoreTypes "../core/types";

module WebhooksEvents {
	type Event<T> = CoreTypes.Event<T>;

	public type WebhookRegisteredEventPayload = {
		ref : Principal;
		name : Text;
		createdAt : Time.Time;
		createdBy : Principal;
	};
	public type WebhookRegisteredEvent = Event<WebhookRegisteredEventPayload>;

	public type WebhookRemovedEventPayload = {
		ref : Principal;
	};

	public type WebhookRemovedEvent = Event<WebhookRemovedEventPayload>;
};
