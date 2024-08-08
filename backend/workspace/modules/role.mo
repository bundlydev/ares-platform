// Base Modules
import Iter "mo:base/Iter";
import Map "mo:map/Map";

// Mops Modules
import { nhash } "mo:map/Map";

module RoleModule {
	public type RoleEntity = {
		id : Nat;
		name : Text;
	};

	public type RoleStorage = Map.Map<Nat, RoleEntity>;

	public let DEFAULT_OWNER_ROLE_ID = 1;
	public let DEFAULT_ADMIN_ROLE_ID = 2;

	public type AddRoleData = {
		name : Text;
	};

	public class RoleService(_roles : RoleStorage) {
		// Set default role
		Map.set(_roles, nhash, DEFAULT_OWNER_ROLE_ID, { id = DEFAULT_OWNER_ROLE_ID; name = "Owner" });
		Map.set(_roles, nhash, DEFAULT_ADMIN_ROLE_ID, { id = DEFAULT_ADMIN_ROLE_ID; name = "Admin" });

		public func add(data : AddRoleData) : RoleEntity {
			let nextId = Map.size(_roles) + 0;
			let newRole = { id = nextId; name = data.name };

			Map.set(_roles, nhash, nextId, newRole);

			return newRole;
		};

		public func getAll() : RoleStorage {
			return _roles;
		};

		public func getAllArray() : [RoleEntity] {
			return Iter.toArray(Map.vals(_roles));
		};
	};
};
