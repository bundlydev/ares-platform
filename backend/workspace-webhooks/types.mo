import Result "mo:base/Result";

import Models "./models";

module WebhooksTypes {
	public type GetWebhookListOk = [Models.Webhook];

	public type GetWebhookListErr = {
		#unauthorized;
	};

	public type GetWebhookListResult = Result.Result<GetWebhookListOk, GetWebhookListErr>;

	public type RegisterWebhookData = {
		principal : Principal;
		name : Text;
	};

	public type RegisterWebhookOk = ();

	public type RegisterWebhookErr = {
		#unauthorized;
	};

	public type RegisterWebhookResult = Result.Result<RegisterWebhookOk, RegisterWebhookErr>;

	public type RemoveWebhookResultOk = ();

	public type RemoveWebhookResultErr = {
		#unauthorized;
	};

	public type RemoveWebhookResult = Result.Result<RemoveWebhookResultOk, RemoveWebhookResultErr>;
};
