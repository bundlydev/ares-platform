import Time "mo:base/Time";

module WebhooksEvents {
	public type WebhookRegisteredEventPayload = {
		ref : Principal;
		name : Text;
		createdAt : Time.Time;
		createdBy : Principal;
	};

	public type WebhookRemovedEventPayload = {
		ref : Principal;
	};

	public type Events = {
		#webhook : {
			#registered : WebhookRegisteredEventPayload;
			#removed : WebhookRemovedEventPayload;
		};
	};
};
