// Mops Modules
import Map "mo:map/Map";

module AccountModels {
	public type Account = {
		identity : Principal;
		username : Text;
		email : Text;
		firstName : Text;
		lastName : Text;
	};

	public type AccountCollection = Map.Map<Principal, Account>;
};
