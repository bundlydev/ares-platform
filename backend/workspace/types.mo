import IamPolicy "./modules/iam/policy";
import IamAccess "./modules/iam/access";

module WorkspaceIamTypes {
	public type ActorContext = {
		creator : Principal;
		owner : Principal;
	};

	/*
   * IAM Method Params
   */

	public type CreatePolicyData = {
		pid : Text;
		ptype : IamPolicy.PolicyType;
		statements : [IamPolicy.PolicyStatement];
	};

	public type CreateRoleData = {
		name : Text;
		description : Text;
		policies : [Text];
	};

	public type GetAccessListOptions = {
		// TODO: Maket it optional
		filters : {
			// TODO: Maket it optional
			itype : IamAccess.AccessIdentityType or { #all };
		};
	};

	public type CreateAccessData = {
		identity : Principal;
		roleId : Text;
		itype : IamAccess.AccessIdentityType;
	};

	/*
   * Users Method Params
   */

	/*
   * Webhooks Method Params
   */

	public type RegisterWebhookData = {
		principal : Principal;
		name : Text;
	};
};
