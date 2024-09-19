import { Principal } from "@dfinity/principal";
import { useRouter } from "next/router";
import { useContext, useEffect, useRef, useState } from "react";

import { useAuth, useCandidActor } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters";
import ModalAssignPermissionUser from "@app/components/ModalAssignPermissionUser";
import ModalAssignRoleUser from "@app/components/ModalAssignRoleUser";
import ModalUsersManagement from "@app/components/ModalUsersManagement";
import { AuthContext } from "@app/context/auth-context";
import { useAuthGuard } from "@app/hooks/useGuard";
import WorkspaceLayout from "@app/layouts/WorkspaceLayout";
import useStore from "@app/store/useStore";

type Workspace = {
  id: string;
  name: string;
};

type WorkspaceData = {
  identity: string;
  createdAt: Date;
  status: boolean | null;
  roles: string[];
  permission: string[];
};

type UsernameData = {
  id: string;
  username: string;
};

export default function ManagementUsersPage(): JSX.Element {
  const { userIAMid } = useStore();
  const { userMid } = useStore();
  const router = useRouter();
  const { currentIdentity } = useAuth();
  useAuthGuard({ isPrivate: true });
  const [showModal, setShowModal] = useState<boolean>(false);
  const [showModalRole, setShowModalRole] = useState<boolean>(false);
  const [showModalPermission, setShowModalPermission] = useState<boolean>(false);
  const [dataNameSearch, setDataNameSearch] = useState<UsernameData[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [rolesList, setRolesList] = useState<WorkspaceData[]>([]);
  const { userManagementId } = useContext(AuthContext);
  const [menuOpen, setMenuOpen] = useState<string | null>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const [assignPrincipal, setAssignPrincipal] = useState<string>("");
  const [rolesAssing, setRolesAssign] = useState<string[]>([]);
  const [permissionAssing, setPermissionAssign] = useState<string[]>([]);
  let workspaceId = router.query["workspace-id"] as string;

  const accountManager = useCandidActor<CandidActors>(
    "accountManager",
    currentIdentity
  ) as CandidActors["accountManager"];

  const workspaceIam = useCandidActor<CandidActors>("workspaceIam", currentIdentity, {
    canisterId: userIAMid,
  }) as CandidActors["workspaceIam"];

  const workspaceUser = useCandidActor<CandidActors>("workspaceUser", currentIdentity, {
    canisterId: userMid,
  }) as CandidActors["workspaceUser"];

  useEffect(() => {
    getPermissions();
  }, []);

  function formatDateFromNanoseconds(nanoseconds: bigint) {
    const milliseconds = Number(BigInt(nanoseconds) / BigInt(1000000));
    const date = new Date(milliseconds);
    const options = { year: "numeric" as const, month: "long" as const, day: "numeric" as const };
    return date.toLocaleDateString("en-US", options);
  }

  const getPermissions = async () => {
    if (!workspaceUser) return;

    const getRolesResult = await workspaceUser.get_access_list();

    if ("ok" in getRolesResult) {
      const rolesOptions = getRolesResult.ok.map((role) => ({
        createdAt: new Date(Number(role.createdAt / BigInt(1000000))),
        identity: role.identity.toString(),
        roles: role.roles,
        permission: role.permissions,
        status: "active" in role.status ? true : "inactive" in role.status ? false : null,
      }));

      setRolesList(rolesOptions);
    } else {
      let error = getRolesResult.err;
      console.error(error);
    }
  };

  const inactiveStatus = async (id: string) => {
    if (!workspaceUser) return;

    const getChangeResult = await workspaceUser.change_access_status(Principal.fromText(id), {
      inactive: null,
    });
    if ("ok" in getChangeResult) {
      getPermissions();
    } else {
      let error = getChangeResult.err;
      console.error(error);
    }
  };
  const activeStatus = async (id: string) => {
    if (!workspaceUser) return;

    const getChangeResult = await workspaceUser.change_access_status(Principal.fromText(id), {
      active: null,
    });
    if ("ok" in getChangeResult) {
      getPermissions();
    } else {
      let error = getChangeResult.err;
      console.error(error);
    }
  };

  const toggleMenu = (identity: string) => {
    setMenuOpen(menuOpen === identity ? null : identity);
  };

  const handleAction = (action: string, identity: string) => {
    switch (action) {
      case "delete":
        deleteIdUser(identity);
        break;
      case "block":
        inactiveStatus(identity);
        break;
      case "unblock":
        activeStatus(identity);
        break;
      case "assignRole":
        setShowModalRole(true);
        break;
      case "assignPermission":
        setShowModalPermission(true);
        break;
      default:
        break;
    }
    setMenuOpen(null); // Cierra el menú después de la acción
  };

  const deleteIdUser = async (idUser: string) => {
    if (!workspaceUser) return;

    setLoading(true);

    try {
      const userId = Principal.fromText(idUser);
      const response = await workspaceUser.delete_access(userId);

      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return;
      }
    } catch (error) {
      console.error("error response", { error });
    } finally {
      setLoading(false);
      window.location.reload();
    }
  };
  return (
    <WorkspaceLayout>
      <div className="flex flex-col w-full">
        <div className="container w-full flex flex-col justify-start items-end bg-slate-100 h-full p-6 rounded-lg">
          <div className="flex justify-between w-full">
            <span className="text-[34px] font-semibold">Users</span>
            <button
              className="bg-green-400 text-white px-8 py-2 rounded-lg mb-4 w-36"
              onClick={() => setShowModal(true)}>
              New
            </button>
          </div>
          <div className="bg-white w-full shadow-md rounded-lg overflow-visible ">
            <div className="grid grid-cols-4 bg-gray-200 p-4 text-gray-700 font-bold">
              <div>Identity</div>
              <div>Created at</div>
              <div>Status</div>
              <div>Action</div>
            </div>
            <div className="divide-y divide-gray-200">
              {rolesList.map((item, index) => (
                <div key={index} className="grid grid-cols-4 p-4 relative">
                  <div>{item.identity}</div>
                  <div>
                    {item.createdAt.toLocaleDateString("en-US", {
                      year: "numeric",
                      month: "long",
                      day: "numeric",
                    })}
                  </div>
                  <div>
                    <div
                      className={`w-16 h-8 rounded-full flex items-center justify-center ${
                        item.status ? "bg-green-500" : "bg-red-500"
                      } text-white`}>
                      {item.status ? "Active" : "Inactive"}
                    </div>
                  </div>
                  <div className="relative">
                    {/* Botón de tres puntos */}
                    <button
                      className="text-gray-500"
                      onClick={() => {
                        toggleMenu(item.identity);
                        setRolesAssign(item.roles);
                        setPermissionAssign(item.permission);
                        setAssignPrincipal(item.identity);
                      }}>
                      &#x2026; {/* Tres puntos */}
                    </button>

                    {/* Menú desplegable */}
                    {menuOpen === item.identity && (
                      <div
                        ref={menuRef}
                        className="absolute right-0 mt-2 w-48 bg-white border border-gray-300 shadow-lg z-50"
                        style={{ zIndex: 9999, top: "100%", position: "absolute" }}>
                        <ul>
                          <li
                            className="px-4 py-2 hover:bg-gray-200 cursor-pointer"
                            onClick={() => handleAction("delete", item.identity)}>
                            Delete
                          </li>
                          {item.status ? (
                            <li
                              className="px-4 py-2 hover:bg-gray-200 cursor-pointer"
                              onClick={() => handleAction("block", item.identity)}>
                              Block
                            </li>
                          ) : (
                            <li
                              className="px-4 py-2 hover:bg-gray-200 cursor-pointer"
                              onClick={() => handleAction("unblock", item.identity)}>
                              Unblock
                            </li>
                          )}
                          <li
                            className="px-4 py-2 hover:bg-gray-200 cursor-pointer"
                            onClick={() => handleAction("assignRole", item.identity)}>
                            Assign Role
                          </li>
                          <li
                            className="px-4 py-2 hover:bg-gray-200 cursor-pointer"
                            onClick={() => handleAction("assignPermission", item.identity)}>
                            Assign Permission
                          </li>
                        </ul>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
        <ModalUsersManagement
          showModal={showModal}
          setShowModal={setShowModal}
          dataNameSearch={dataNameSearch}
        />
        {showModalRole && (
          <ModalAssignRoleUser
            assignRoles={rolesAssing}
            assignPrincipal={assignPrincipal}
            showModal={showModalRole}
            setShowModal={setShowModalRole}
            dataNameSearch={dataNameSearch}
          />
        )}
        {showModalPermission && (
          <ModalAssignPermissionUser
            showModal={showModalPermission}
            setShowModal={setShowModalPermission}
            dataNameSearch={dataNameSearch}
            assignRoles={permissionAssing}
            assignPrincipal={assignPrincipal}
          />
        )}
      </div>
    </WorkspaceLayout>
  );
}
