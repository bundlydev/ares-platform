// Base Modules
import Principal "mo:base/Principal";

// Mops Modules
import Map "mo:map/Map";
import { nhash } "mo:map/Map";

module CyclesLedgerModule {
	public type CycleTransaction = {
		amount : Nat;
		recipient : Principal;
		transactionType : {
			#deposit;
			#withdrawal;
		};
		transactionDate : Int;
	};

	public type CyclesLedgerStorage = Map.Map<Nat, CycleTransaction>;

	public class CyclesLedgerService(_storage : CyclesLedgerStorage) {
		private func getNextId() : Nat {
			let nextId = Map.size(_storage) + 1;
			return nextId;
		};

		public func addTransaction(_newEntry : CycleTransaction) : () {
			Map.set<Nat, CycleTransaction>(_storage, nhash, getNextId(), _newEntry);
		};

		public func getTotalBalance() : Nat {
			var balance : Nat = 0;

			for (item in Map.vals(_storage)) {
				switch (item.transactionType) {
					case (#deposit) {
						balance += item.amount;
					};
					case (#withdrawal) {
						balance -= item.amount;
					};
				};
			};

			return balance;
		};

		public func getUserBalance(_user : Principal) : Nat {
			var balance : Nat = 0;

			for (item in Map.vals(_storage)) {
				if (Principal.equal(item.recipient, _user)) {
					switch (item.transactionType) {
						case (#deposit) {
							balance += item.amount;
						};
						case (#withdrawal) {
							balance -= item.amount;
						};
					};
				};
			};

			return balance;
		};
	};
};
