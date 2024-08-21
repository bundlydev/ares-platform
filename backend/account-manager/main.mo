// Base Modules
import Principal "mo:base/Principal";
import List "mo:base/List";
import Array "mo:base/Array";
import Text "mo:base/Text";

// Mops Modules
import Map "mo:map/Map";
import { phash } "mo:map/Map";

import TextValidator "mo:validators/Text";

import AccountModels "./models";
import AccountTypes "./types";

actor class AccountManager() {
	stable let _accounts : AccountModels.AccountCollection = Map.new<Principal, AccountModels.Account>();

	private func check_if_account_exists(identity : Principal) : Bool {
		for (key in Map.keys(_accounts)) {
			if (Principal.equal(key, identity)) {
				return true;
			};
		};

		return false;
	};

	private func get_account_by_id(id : Principal) : ?AccountModels.Account {
		return Map.get(_accounts, phash, id);
	};

	public shared ({ caller }) func create(data : AccountTypes.CreateAccountData) : async AccountTypes.CreateAccountResult {
		if (Principal.isAnonymous(caller)) return #err(#unauthorized);

		if (check_if_account_exists(caller)) return #err(#identityAlreadyRegistered);

		for (account in Map.vals(_accounts)) {
			if (account.username == data.username) {
				return #err(#usernameAlreadyExists);
			};
		};

		if (TextValidator.isEmpty(data.username)) {
		// TODO: Validate username with regex ^[a-zA-Z0-9_]{5,15}$
			return #err(#requiredField("username"));
		} else if (TextValidator.isEmpty(data.email)) {
			// TODO: Validate email with regex ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
			return #err(#requiredField("email"));
		} else if (TextValidator.isEmpty(data.firstName)) {
			// TODO: Validate first name with regex /^[A-Za-zÀ-ÿ]+([-'\s][A-Za-zÀ-ÿ]+)*$/
			return #err(#requiredField("firstName"));
		} else if (TextValidator.isEmpty(data.lastName)) {
			// TODO: Validate last name with regex /^[A-Za-zÀ-ÿ]+([-'\s][A-Za-zÀ-ÿ]+)*$/
			return #err(#requiredField("lastName"));
		};

		let newAccount : AccountModels.Account = { data with identity = caller };

		Map.set<Principal, AccountModels.Account>(_accounts, phash, newAccount.identity, newAccount);

		return #ok(newAccount);
	};

	public query ({ caller }) func get_my_info() : async AccountTypes.GetMyInfoResult {
		if (Principal.isAnonymous(caller)) return #err(#unauthorized);

		switch (get_account_by_id(caller)) {
			case (?account) {
				return #ok(account);
			};
			case (null) {
				return #err(#accountNotFound);
			};
		};
	};

	public shared query ({ caller }) func account_exists(identity : Principal) : async AccountTypes.AccountExistsResult {
		if (Principal.isAnonymous(caller)) return #err(#unauthorized);

		return #ok(check_if_account_exists(identity));
	};

	public shared query ({ caller }) func get_account(identity : Principal) : async AccountTypes.GetAccountResult {
		if (Principal.isAnonymous(caller)) return #err(#unauthorized);

		switch (get_account_by_id(identity)) {
			case (?account) {
				return #ok(account);
			};
			case (null) {
				return #err(#accountNotFound);
			};
		};
	};

	// TODO: Test this
	public shared query ({ caller }) func find_account_by_username_chunk(chunk : Text) : async AccountTypes.FindAccountsByUsernameChunkResult {
		if (Principal.isAnonymous(caller)) return #err(#unauthorized);

		var accountList : List.List<AccountTypes.FindAccountsByUsernameChunkResultOkItem> = List.nil();

		for (account in Map.vals(_accounts)) {
			if (Text.startsWith(account.username, #text(chunk))) {
				let newItem = { id = account.identity; username = account.username };
				accountList := List.push<AccountTypes.FindAccountsByUsernameChunkResultOkItem>(newItem, accountList);
			};
		};

		let accountArray = Array.filter<AccountTypes.FindAccountsByUsernameChunkResultOkItem>(
			List.toArray(accountList),
			func(acc) = acc.id != caller,
		);

		let maxResultLength = if (Array.size(accountArray) < 10) Array.size(accountArray) else 10;

		let result = Array.subArray(accountArray, 0, maxResultLength);

		return #ok(result);
	};
};
