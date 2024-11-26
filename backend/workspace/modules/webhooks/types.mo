import IamEvents "../iam/events";
import UsersEvents "../users/events";
import WebhookEvents "./events";

module WebhookTypes {
	public type IamEvent = IamEvents.Events;
	public type UserEvent = UsersEvents.Events;
	public type WebhookEvent = WebhookEvents.Events;

	public type Event = {
		#iam : IamEvents.Events;
		#user : UsersEvents.Events;
		#webhook : WebhookEvents.Events;
	};

	public type Subscriber = actor { callback : shared (event : Event) -> async () };
};
