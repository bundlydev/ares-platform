// Base Modules
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Result "mo:base/Result";
import Text "mo:base/Text";

// Mops Modules
import Map "mo:map/Map";
import { phash } "mo:map/Map";

import Roles "./Roles";
import Permissions "./Permissions";

module Access {
	public type Access = {
		identity : Principal;
		roles : [Text];
		permissions : [Text];
	};

	public type AccessRepository = Map.Map<Principal, Access>;

	public class AccessService(repository : AccessRepository, rolesService : Roles.RolesService, permissionsService : Permissions.PermissionsService) {
		public func hasPermission(identity : Principal, permission : Text) : Bool {
			switch (get(identity)) {
				case (?access) {
					if (
						Array.find<Text>(
							access.permissions,
							func(p : Text) : Bool {
								return p == permission;
							},
						) != null
					) {
						return true;
					};

					for (roleId in access.roles.vals()) {
						switch (rolesService.get(roleId)) {
							case (?role) {
								if (
									Array.find<Text>(
										role.permissions,
										func(p : Text) : Bool {
											return p == permission;
										},
									) != null
								) {
									return true;
								};
							};
							case null {};
						};
					};

					return false;
				};
				case (null) {
					return false;
				};
			};
		};

		public func getAll() : [Access] {
			let accessIter = Map.vals(repository);
			let accessArray = Iter.toArray(accessIter);

			return accessArray;
		};

		public func get(accessId : Principal) : ?Access {
			return Map.get(repository, phash, accessId);
		};

		type CreateAccessResultOk = Access;

		type CreateAccessResultErr = {
			#accessAlreadyExists;
			#rolesDoNotExist : [Text];
			#permissionsDoNotExist : [Text];
		};

		type CreateAccessResult = Result.Result<CreateAccessResultOk, CreateAccessResultErr>;

		public func create(identity : Principal, roles : [Text], permissions : [Text]) : CreateAccessResult {
			switch (get(identity) == null) {
				case (false) return #err(#accessAlreadyExists);
				case (true) {};
			};

			let missingRoles = Array.mapFilter<Text, Text>(
				roles,
				func(roleToAdd) {
					switch (rolesService.get(roleToAdd)) {
						case (?_role) { return null };
						case (null) { return ?roleToAdd };
					};
				},
			);

			if (Array.size(missingRoles) > 0) {
				return #err(#rolesDoNotExist(missingRoles));
			};

			let missingPermissions = Array.mapFilter<Text, Text>(
				permissions,
				func(permissionToAdd) {
					switch (permissionsService.exists(permissionToAdd)) {
						case (true) { return null };
						case (false) { return ?permissionToAdd };
					};
				},
			);

			if (Array.size(missingPermissions) > 0) {
				return #err(#permissionsDoNotExist(missingPermissions));
			};

			let newAccess = {
				identity = identity;
				roles = roles;
				permissions = permissions;
			};

			ignore Map.put(repository, phash, identity, newAccess);

			return #ok(newAccess);
		};

		public func delete(id : Principal) : Bool {
			switch (Map.remove(repository, phash, id)) {
				case (?_access) { return true };
				case (null) { return false };
			};
		};

		type AddRoleToAccessResultOk = ();

		type AddRoleToAccessResultErr = {
			#accessDoesNotExist;
			#roleAlreadyAdded;
			#roleDoesNotExist;
		};

		type AddRoleToAccessResult = Result.Result<AddRoleToAccessResultOk, AddRoleToAccessResultErr>;

		public func addRole(accessId : Principal, roleId : Text) : AddRoleToAccessResult {
			switch (get(accessId)) {
				case (?access) {
					switch (rolesService.get(roleId)) {
						case (?_) {};
						case (null) return #err(#roleDoesNotExist);
					};

					if (Array.find<Text>(access.roles, func(r : Text) : Bool { return r == roleId }) != null) {
						return #err(#roleAlreadyAdded);
					};

					let updatedRoles = Array.append<Text>(access.roles, [roleId]);

					let accessUpdated = { access with roles = updatedRoles };

					ignore Map.put(repository, phash, accessId, accessUpdated);

					return #ok();
				};
				case (null) #err(#accessDoesNotExist);
			};
		};

		type RemoveRoleResultOk = ();

		type RemoveRoleResultErr = {
			#accessDoesNotExist;
		};

		type RemoveRoleResult = Result.Result<RemoveRoleResultOk, RemoveRoleResultErr>;

		public func removeRole(accessId : Principal, roleId : Text) : RemoveRoleResult {
			switch (get(accessId)) {
				case (?access) {
					let updatedRoles = Array.filter<Text>(access.roles, func(r : Text) : Bool { return r != roleId });

					let accessUpdated = { access with roles = updatedRoles };

					ignore Map.put(repository, phash, accessId, accessUpdated);

					return #ok();
				};
				case (null) #err(#accessDoesNotExist);
			};
		};

		type AddPermissionToAccessResultOk = ();

		type AddPermissionToAccessResultErr = {
			#accessDoesNotExist;
			#permissionAlreadyAdded;
			#permissionDoesNotExist;
		};

		type AddPermissionToAccessResult = Result.Result<AddPermissionToAccessResultOk, AddPermissionToAccessResultErr>;

		public func addPermission(accessId : Principal, permissionId : Text) : AddPermissionToAccessResult {
			switch (get(accessId)) {
				case (?access) {
					switch (permissionsService.get(permissionId)) {
						case (?_) {};
						case (null) return #err(#permissionDoesNotExist);
					};

					if (Array.find<Text>(access.permissions, func(p : Text) : Bool { return p == permissionId }) != null) {
						return #err(#permissionAlreadyAdded);
					};

					let updatedPermissions = Array.append<Text>(access.permissions, [permissionId]);

					let accessUpdated = { access with permissions = updatedPermissions };

					ignore Map.put(repository, phash, accessId, accessUpdated);

					return #ok();
				};
				case (null) #err(#accessDoesNotExist);
			};
		};

		type RemovePermissionFromAccessResultOk = ();

		type RemovePermissionFromAccessResultErr = {
			#accessDoesNotExist;
		};

		type RemovePermissionFromAccessResult = Result.Result<RemovePermissionFromAccessResultOk, RemovePermissionFromAccessResultErr>;

		public func removePermission(accessId : Principal, permissionId : Text) : RemovePermissionFromAccessResult {
			switch (get(accessId)) {
				case (?access) {
					let updatedPermissions = Array.filter<Text>(access.permissions, func(p : Text) : Bool { return p != permissionId });

					let accessUpdated = { access with permissions = updatedPermissions };

					ignore Map.put(repository, phash, accessId, accessUpdated);

					return #ok();
				};
				case (null) #err(#accessDoesNotExist);
			};
		};
	};
};
