import Principal "mo:base/Principal";
import List "mo:base/List";

module CyclesLedger {
	public type CycleTransaction = {
		amount : Nat;
		recipient : Principal;
		transactionType : {
			#deposit;
			#withdrawal;
		};
		transactionDate : Int;
	};

	public type CyclesLedgerStorage = List.List<CycleTransaction>;

	public class CyclesLedgerService(_cyclesLedgerStorage : CyclesLedgerStorage) {
		public func addTransaction(_newEntry : CycleTransaction) : () {
			// TODO: Fix this, currently don't update the storage
			ignore List.push(_newEntry, _cyclesLedgerStorage);
		};

		public func getTotalBalance() : Nat {
			var balance : Nat = 0;

			for (item in List.toIter(_cyclesLedgerStorage)) {
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

			for (item in List.toIter(_cyclesLedgerStorage)) {
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
