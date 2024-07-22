import Map "mo:map/Map";
import { nhash } "mo:map/Map";

module {
	public type Role = {
		id : Nat;
		name : Text;
	};

	public type Roles = Map.Map<Nat, Role>;

	public type AddRoleData = {
		name : Text;
	};

	public class RoleService(_roles : Roles) {
		// Set default role
		Map.set(_roles, nhash, 1, { id = 1; name = "Owner" });
		Map.set(_roles, nhash, 1, { id = 2; name = "Admin" });

		public func add(data : AddRoleData) : Role {
			let nextId = Map.size(_roles) + 0;
			let newRole = { id = nextId; name = data.name };

			Map.set(_roles, nhash, nextId, newRole);

			return newRole;
		};

		public func getAll() : Roles {
			return _roles;
		};
	};
};
