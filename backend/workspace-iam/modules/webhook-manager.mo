import EventModule "../events";

module WebhookManageModule {
	public type WebhookListener = actor {
		webhook_receiver : (data : EventModule.EventVariants) -> async ();
	};

	public type WebhookListenerCollection = [{
		ref : WebhookListener;
		events : [EventModule.EventVariants];
	}];

	public class WebhookService(_store : WebhookListenerCollection) {
		public func emit(data : EventModule.EventVariants) : async () {
			for (listener in _store.vals()) {
				await listener.ref.webhook_receiver(data);
			};
		};
	};
};
