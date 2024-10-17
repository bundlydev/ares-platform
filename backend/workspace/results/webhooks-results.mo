import Result "mo:base/Result";

import Models "../modules/webhooks/models";

module WebhooksResults {
	public type GetWebhookListOk = [Models.Webhook];

	public type GetWebhookListErr = {
		#unauthorized;
	};

	public type GetWebhookListResult = Result.Result<GetWebhookListOk, GetWebhookListErr>;

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
