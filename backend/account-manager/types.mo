import AccountModels "./models";
import Result "mo:base/Result";

module AccountTypes {
	public type CreateAccountData = {
		username : Text;
		firstName : Text;
		lastName : Text;
		email : Text;
	};

	public type CreateAccountResultOk = AccountModels.Account;

	public type CreateAccountResultErr = {
		#unauthorized;
		#identityAlreadyRegistered;
		#usernameAlreadyExists;
		#emailAlreadyExists;
		#requiredField : Text;
	};

	public type CreateAccountResult = Result.Result<CreateAccountResultOk, CreateAccountResultErr>;

	public type GetMyInfoResultOk = AccountModels.Account;

	public type GetMyInfoResultErr = {
		#unauthorized;
		#accountNotFound;
	};

	public type GetMyInfoResult = Result.Result<GetMyInfoResultOk, GetMyInfoResultErr>;

	public type AccountExistsResultOk = Bool;

	public type AccountExistsResultErr = {
		#unauthorized;
	};

	public type AccountExistsResult = Result.Result<AccountExistsResultOk, AccountExistsResultErr>;

	public type GetAccountResultOk = AccountModels.Account;

	public type GetAccountResultErr = {
		#unauthorized;
		#accountNotFound;
	};

	public type GetAccountResult = Result.Result<GetAccountResultOk, GetAccountResultErr>;

	public type FindAccountsByUsernameChunkResultOkItem = {
		id : Principal;
		username : Text;
	};

	public type FindAccountsByUsernameChunkResultOk = [FindAccountsByUsernameChunkResultOkItem];

	public type FindAccountsByUsernameChunkResultErr = {
		#unauthorized;
		#accountNotFound;
		#chunkTooShort;
	};

	public type FindAccountsByUsernameChunkResult = Result.Result<FindAccountsByUsernameChunkResultOk, FindAccountsByUsernameChunkResultErr>;
};
