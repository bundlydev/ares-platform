import Principal "mo:base/Principal";
import Map "mo:map/Map";
import { phash } "mo:map/Map";

module {
	public type Profile = {
		username : Text;
		email : Text;
		firstName : Text;
		lastName : Text;
	};

	public type Profiles = Map.Map<Principal, Profile>;

	public type CreateProfileData = {
		username : Text;
		firstName : Text;
		lastName : Text;
		email : Text;
	};

	public class ProfileService(_profiles : Profiles) {
		public func create(id : Principal, data : CreateProfileData) {
			// TODO: Validate data
			Map.set<Principal, Profile>(_profiles, phash, id, data);
		};

		public func getById(id : Principal) : ?Profile {
			return Map.get(_profiles, phash, id);
		};

		public func getByUsername(username : Text) : ?Profile {
			for (profile in Map.vals(_profiles)) {
				if (profile.username == username) {
					return ?profile;
				};
			};

			return null;
		};
	};
};
