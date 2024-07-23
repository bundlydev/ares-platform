import Map "mo:map/Map";
import { nhash } "mo:map/Map";
import Iter "mo:base/Iter";

module {
	public type Role = {
		id : Nat;
		name : Text;
	};

	public type Roles = Map.Map<Nat, Role>;

	public let DEFAULT_OWNER_ROLE_ID = 1;
	public let DEFAULT_ADMIN_ROLE_ID = 2;

	public type AddRoleData = {
		name : Text;
	};

	public class RoleService(_roles : Roles) {
		// Set default role
		Map.set(_roles, nhash, DEFAULT_OWNER_ROLE_ID, { id = DEFAULT_OWNER_ROLE_ID; name = "Owner" });
		Map.set(_roles, nhash, DEFAULT_ADMIN_ROLE_ID, { id = DEFAULT_ADMIN_ROLE_ID; name = "Admin" });

		public func add(data : AddRoleData) : Role {
			let nextId = Map.size(_roles) + 0;
			let newRole = { id = nextId; name = data.name };

			Map.set(_roles, nhash, nextId, newRole);

			return newRole;
		};

		public func getAll() : Roles {
			return _roles;
		};

		public func getAllArray() : [Role] {
			return Iter.toArray(Map.vals(_roles));
		};
	};
};
