import CoreTypes "../core/types";
import Policy "./policy";

module IamEvents {
	type Event<T> = CoreTypes.Event<T>;

	// Policy Events
	public type PolicyCreatedEventPayload = Policy.Policy;
	public type PolicyCreatedEvent = Event<PolicyCreatedEventPayload>;

	// Role Events

	// Access Events
};
