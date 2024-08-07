import Principal "mo:base/Principal";
import List "mo:base/List";
import Debug "mo:base/Debug";

module CyclesLedger {
	public type CyclesLedgerEntity = {
		amount : Nat;
		recipient : Principal;
		transactionDate : Int;
	};

	public type CyclesLederModel = List.List<CyclesLedgerEntity>;

	public class CyclesLedgerService(_cyclesLedgerStorage : CyclesLederModel) {
		public func addEntry(_newEntry : CyclesLedgerEntity) : () {
			// TODO: Fix this, currently don't update the storage
			ignore List.push(_newEntry, _cyclesLedgerStorage);
		};

		public func getUserBalance(_user : Principal) : Nat {
			var _balance : Nat = 0;

			for (item in List.toIter(_cyclesLedgerStorage)) {
				if (Principal.equal(item.recipient, _user)) {
					Debug.print(debug_show (item.amount));
					_balance += item.amount;
				};
			};

			return _balance;
		};
	};
};
