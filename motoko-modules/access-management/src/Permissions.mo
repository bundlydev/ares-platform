// Base Modules
import Prim "mo:prim";
import Iter "mo:base/Iter";
import Result "mo:base/Result";

// Mops Modules
import Set "mo:map/Set";

module {
	public type Permission = {
		action : Text;
		description : Text;
	};

	public func hashPermission(permission : Permission) : Nat32 {
		Prim.hashBlob(Prim.encodeUtf8(permission.action)) & 0x3fffffff;
	};

	public let phash = (
		hashPermission,
		func(a : Permission, b : Permission) = a.action == b.action,
	) : Set.HashUtils<Permission>;

	public type PermissionsRepository = Set.Set<Permission>;

	public type CreatePermissionData = {
		action : Text;
		description : Text;
	};

	public class PermissionsService(repository : PermissionsRepository) {
		public func getAll() : [Permission] {
			let permissionIter = Set.keys(repository);
			let permissionArray = Iter.toArray(permissionIter);

			return permissionArray;
		};

		public func exists(action : Text) : Bool {
			let permission = {
				action = action;
				description = "";
			};

			return Set.has<Permission>(repository, phash, permission);
		};

		type CreatePermissionResultOk = Permission;

		type CreatePermissionResultErr = {
			#actionAlreadyRegistered;
		};

		type CreatePermissionResult = Result.Result<CreatePermissionResultOk, CreatePermissionResultErr>;

		public func create(data : CreatePermissionData) : CreatePermissionResult {
			if (exists(data.action)) {
				return #err(#actionAlreadyRegistered);
			};

			let newPermission = {
				action = data.action;
				description = data.description;
			};

			ignore Set.put<Permission>(repository, phash, newPermission);

			#ok(newPermission);
		};

		public func delete(action : Text) : Bool {
			let permission = {
				action = action;
				description = "";
			};

			return Set.remove<Permission>(repository, phash, permission);
		};

		public func get(action : Text) : ?Permission {
			return Set.find<Permission>(repository, func(permission) = permission.action == action);
		};
	};
};
