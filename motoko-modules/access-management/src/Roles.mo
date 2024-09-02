// Base Modules
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Result "mo:base/Result";

// Mops Modules
import Map "mo:map/Map";
import { thash } "mo:map/Map";

import Permissions "./Permissions";

module {
	public type Role = {
		name : Text;
		description : Text;
		permissions : [Text];
	};

	public type RolesRepository = Map.Map<Text, Role>;

	public class RolesService(repository : RolesRepository, permissionsService : Permissions.PermissionsService) {
		public func getAll() : [Role] {
			let permissionIter = Map.vals(repository);
			let permissionArray = Iter.toArray(permissionIter);

			return permissionArray;
		};

		public func get(name : Text) : ?Role {
			return Map.get(repository, thash, name);
		};

		public func exists(name : Text) : Bool {
			switch (get(name)) {
				case (?_) { return true };
				case (null) { return false };
			};
		};

		type CreatePermissionData = {
			name : Text;
			description : Text;
			permissions : [Text];
		};

		type CreatePermissionResultOk = Role;

		type CreatePermissionResultErr = {
			#duplicatedRoleName;
			#permissionsDoNotExist : [Text];
		};

		type CreatePermissionResult = Result.Result<CreatePermissionResultOk, CreatePermissionResultErr>;

		public func create(data : CreatePermissionData) : CreatePermissionResult {
			// TODO: Validate name format

			switch (exists(data.name)) {
				case (true) { return #err(#duplicatedRoleName) };
				case (false) {};
			};

			let permissions = permissionsService.getAll();

			let missingPermissions = Array.mapFilter<Text, Text>(
				data.permissions,
				func(permissionToAdd) {
					switch (Array.find<Permissions.Permission>(permissions, func permission = permission.action == permissionToAdd)) {
						case (?permission) { return null };
						case (null) { return ?permissionToAdd };
					};
				},
			);

			if (Array.size(missingPermissions) > 0) {
				return #err(#permissionsDoNotExist(missingPermissions));
			};

			let newRole = {
				name = data.name;
				description = data.description;
				permissions = data.permissions;
			};

			ignore Map.put(repository, thash, newRole.name, newRole);

			return #ok(newRole);
		};

		public func delete(id : Text) : Bool {
			switch (Map.remove(repository, thash, id)) {
				case (?_role) return true;
				case (null) return false;
			};
		};

		// TODO: Move to upper level
		type AddPermissionResultOk = ();

		type AddPermissionResultErr = {
			#roleDoesNotExist;
			#permissionDoesNotExist;
			#permissionAlreadyAdded;
		};

		type AddPermissionResult = Result.Result<AddPermissionResultOk, AddPermissionResultErr>;

		public func addPermission(roleId : Text, permissionId : Text) : AddPermissionResult {
			switch (get(roleId)) {
				case (?role) {
					switch (permissionsService.exists(permissionId)) {
						case (true) {};
						case (false) { return #err(#permissionDoesNotExist) };
					};

					if (Array.find<Text>(role.permissions, func(r : Text) : Bool { return r == roleId }) != null) {
						return #err(#permissionAlreadyAdded);
					};

					let newPermissions = Array.append(role.permissions, [permissionId]);

					let updatedRole = { role with permissions = newPermissions };

					ignore Map.put(repository, thash, updatedRole.name, updatedRole);

					#ok();
				};
				case (null) #err(#roleDoesNotExist);
			};
		};

		type RemovePermissionResultOk = ();

		type RemovePermissionResultErr = {
			#roleDoesNotExist;
		};

		type RemovePermissionResult = Result.Result<RemovePermissionResultOk, RemovePermissionResultErr>;

		public func removePermission(roleId : Text, permissionId : Text) : RemovePermissionResult {
			switch (get(roleId)) {
				case (?role) {
					let newPermissions = Array.filter<Text>(role.permissions, func pid = pid != permissionId);

					let updatedRole = { role with permissions = newPermissions };

					ignore Map.put(repository, thash, updatedRole.name, updatedRole);

					#ok();
				};
				case (null) #err(#roleDoesNotExist);
			};
		};
	};
};
