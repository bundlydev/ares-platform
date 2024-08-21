module PolicyActionModule {
	public type PolicyAction = {
		action : Text;
		description : Text;
	};

	public type PolicyActions = {
		ACTIONS_READ : PolicyAction;
		POLICY_READ : PolicyAction;
		POLICY_WRITTE : PolicyAction;
		ROLE_READ : PolicyAction;
		ROLE_WRITTE : PolicyAction;
		ACCESS_READ : PolicyAction;
		ACCESS_WRITTE : PolicyAction;
	};

	public let POLICY_ACTIONS : PolicyActions = {
		ACTIONS_READ = { action = "iam:actions:read"; description = "Read all available actions" };
		POLICY_READ = { action = "iam:policy:read"; description = "Read all available actions" };
		POLICY_WRITTE = { action = "iam:policy:writte"; description = "Read all available actions" };
		ROLE_READ = {
			action = "iam:role:read";
			description = "Read all available actions";
		};
		ROLE_WRITTE = { action = "iam:role:writte"; description = "Read all available actions" };
		ACCESS_READ = { action = "iam:access:read"; description = "Read all available actions" };
		ACCESS_WRITTE = { action = "iam:access:writte"; description = "Read all available actions" };
	};
};
