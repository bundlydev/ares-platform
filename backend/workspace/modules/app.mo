// Base Modules
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";

// Mops Modules
import Map "mo:map/Map";
import { phash } "mo:map/Map";

// Local Modules
import WebhookModule "./webhook";

module AppModule {
	public type AppEntity = {
		principal : Principal;
		name : Text;
	};

	public type AppStorage = Map.Map<Principal, AppEntity>;

	public type GetAllAppsResult = AppStorage;

	public type AddAppResultOk = ();

	public type AddAppResultErr = {
		#principalAlreadyRegistered;
		#nameAlreadyTaken;
		#noEmptyNameAllowed;
	};

	public type AddAppResult = Result.Result<AddAppResultOk, AddAppResultErr>;

	public type RemoveAppResultOk = ();

	public type RemoveAppResultErr = {
		#appNotFound;
	};

	public type RemoveAppResult = Result.Result<RemoveAppResultOk, RemoveAppResultErr>;

	public class AppService(_storage : AppStorage, webhookService : WebhookModule.WebhookService) {
		public func getAll() : GetAllAppsResult {
			return _storage;
		};

		public func getAllArray() : [AppEntity] {
			return Iter.toArray(Map.vals(_storage));
		};

		public func add(principal : Principal, name : Text) : async AddAppResult {
			// TODO: Is there a way to validate if the appId is a valid Canister ID in the network?
			let existingApp = Map.get<Principal, AppEntity>(_storage, phash, principal);

			if (existingApp != null) {
				return #err(#principalAlreadyRegistered);
			};

			if (Map.some<Principal, AppEntity>(_storage, func((_, app)) = app.name == name)) {
				return #err(#nameAlreadyTaken);
			};

			if (name == "") {
				return #err(#noEmptyNameAllowed);
			};

			let newApp = { principal; name };

			Map.set<Principal, AppEntity>(_storage, phash, principal, newApp);

			ignore webhookService.emit(#appAdded(newApp));

			#ok();
		};

		public func remove(principal : Principal) : async RemoveAppResult {
			let existingApp = Map.get<Principal, AppEntity>(_storage, phash, principal);

			switch (existingApp) {
				case null {
					return #err(#appNotFound);
				};
				case (?app) {
					ignore Map.remove<Principal, AppEntity>(_storage, phash, principal);

					let appRemovedEvent = { principal; name = app.name };

					ignore webhookService.emit(#appRemoved(appRemovedEvent));

					#ok();
				};
			};
		};
	};
};
