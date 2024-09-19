import { Principal } from "@dfinity/principal";
import { useRouter } from "next/router";
import { useContext, useEffect, useRef, useState } from "react";

import { useAuth, useCandidActor } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters";
import LoadingSpinner from "@app/components/LoadingSpinner";
import ModalRoles from "@app/components/ModalRoles";
import ModalRolesManagement from "@app/components/ModalRolesManagement";
import { AuthContext } from "@app/context/auth-context";
import { useAuthGuard } from "@app/hooks/useGuard";
import WorkspaceLayout from "@app/layouts/WorkspaceLayout";
import useStore from "@app/store/useStore";

type Workspace = {
  id: string;
  name: string;
};
type WorkspaceData = {
  name: string;
  description: string;
  permissions: string[];
};
type UsernameData = {
  id: string;
  username: string;
};

export default function ManagementRolesPage(): JSX.Element {
  const { userIAMid } = useStore();
  const { userMid } = useStore();
  const router = useRouter();
  const { currentIdentity } = useAuth();
  useAuthGuard({ isPrivate: true });
  const [showModal, setShowModal] = useState<boolean>(false);
  const [dataNameSearch, setDataNameSearch] = useState<UsernameData[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [workspaceIsOpen, setWorkspaceIsOpen] = useState<boolean>(false);
  const [rolesList, setRolesList] = useState<WorkspaceData[]>([]);
  const { userManagementId } = useContext(AuthContext);

  const workspaceRef = useRef<HTMLDivElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

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

  const getPermissions = async () => {
    if (!workspaceUser) return;

    const getRolesResult = await workspaceUser.get_roles();
    if ("ok" in getRolesResult) {
      const rolesOptions = getRolesResult.ok.map((role) => ({
        permissions: role.permissions,
        name: role.name,
        description: role.description,
      }));
      setRolesList(rolesOptions);
    } else {
      let error = getRolesResult.err;
      console.error(error);
    }
  };

  const getListFindName = async (nameText: string) => {
    try {
      const response = await accountManager.find_account_by_username_chunk(nameText);
      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return;
      }
      const listName = "ok" in response ? response.ok : undefined;
      if (listName) {
        const searchNameList = listName.map((member) => ({
          id: member.id.toString(),
          username: member.username,
        }));

        setDataNameSearch(searchNameList);
      }
    } catch (error) {
      console.error("error response", { error });
    }
  };

  const deleteIdapp = async (idApp: string) => {
    if (!workspaceIam) return;

    setLoading(true);

    try {
      const appId = Principal.fromText(idApp);
      const response = await workspaceIam.delete_access(appId);

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
  const handleToggle = () => {
    setIsOpen(!isOpen);
  };

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        menuRef.current &&
        !menuRef.current.contains(event.target as Node) &&
        workspaceRef.current &&
        !workspaceRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
        setWorkspaceIsOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [menuRef, workspaceRef]);
  return (
    <WorkspaceLayout>
      <div className="flex flex-col w-full ">
        <div className="container w-full flex flex-col justify-start items-end  bg-slate-100 h-full p-6 rounded-lg">
          <div className="flex justify-between w-full">
            <span className="text-[34px] font-semibold">Roles</span>
            <button
              className="bg-green-400 text-white px-4 py-2 rounded-lg mb-4 w-36"
              onClick={() => setShowModal(true)}>
              + Create Role
            </button>
          </div>
          <div className="bg-white w-full shadow-md rounded-lg overflow-hidden ">
            <div className="grid grid-cols-3 bg-gray-200 p-4 text-gray-700 font-bold">
              <div>Name</div>
              <div>Description</div>
              <div>Action</div>
            </div>
            <div className="divide-y divide-gray-200">
              {rolesList.map((item, index) => (
                <div key={index} className="grid grid-cols-3 p-4">
                  <div>{item.name}</div>
                  <div>{item.description}</div>
                  <div>
                    <button
                      className="bg-red-500 text-white py-1 px-3 rounded-lg"
                      onClick={() => {
                        deleteIdapp(item.name);
                      }}
                      disabled={loading}>
                      {loading ? <LoadingSpinner /> : "Delete"}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
        <ModalRolesManagement
          showModal={showModal}
          setShowModal={setShowModal}
          getListFindName={getListFindName}
          dataNameSearch={dataNameSearch}
        />
      </div>
    </WorkspaceLayout>
  );
}
