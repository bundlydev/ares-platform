import { Principal } from "@dfinity/principal";
import React, { useContext, useEffect, useRef, useState } from "react";

import { LogoutButton, useAuth, useCandidActor, useIdentities } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters/index";
import { useAuthGuard } from "@app/hooks/useGuard";
import WorkspaceLayout from "@app/layouts/WorkspaceLayout";

import LoadingSpinner from "@app/components/LoadingSpinner";
import Menu from "@app/components/Menu";
import Modal from "@app/components/Modal";
import SelectWorkspace from "@app/components/SelectWorkspace";
import { AuthContext } from "@app/context/auth-context";
import { useProfile } from "@app/hooks/useProfile";
import { useWorkspaces } from "@app/hooks/useWorkspaces";

export default function WorkspaceUsersPage() {
  type Workspace = {
    id: string;
    name: string;
  };
  type WorkspaceData = {
    id: string;
    name: string;
    role: string;
  };
  type UsernameData = {
    id: string;
    username: string;
  };

  const { currentIdentity } = useAuth();
  const { workspaceId, ownerId } = useContext(AuthContext);
  const [showModal, setShowModal] = useState<boolean>(false);
  const [showModalDelete, setShowModalDelete] = useState<boolean>(false);
  const [deleteItem, setDeleteItem] = useState<string>("");
  const [dataNameSearch, setDataNameSearch] = useState<UsernameData[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const workspaces = useWorkspaces();
  const profiles = useProfile();
  const [workspaceIsOpen, setWorkspaceIsOpen] = useState<boolean>(false);
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const identity = useIdentities();
  const loadingAuth = useAuthGuard({ isPrivate: true });
  const [workspaceMembers, setWorkspaceMembers] = useState<WorkspaceData[]>([]);

  const workspaceRef = useRef<HTMLDivElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  const accountManager = useCandidActor<CandidActors>(
    "accountManager",
    currentIdentity
  ) as CandidActors["accountManager"];

  const workspaceIam = workspaceId
    ? (useCandidActor<CandidActors>("workspaceIam", currentIdentity, {
        canisterId: workspaceId,
      }) as CandidActors["workspaceIam"])
    : null;

  useEffect(() => {
    getWorkspaceMembers();
  }, [workspaceId]);

  const getWorkspaceMembers = async () => {
    if (!workspaceIam) return;

    let getMembersResult = await workspaceIam.get_access_list({ filters: { itype: { user: null } } });

    if ("ok" in getMembersResult) {
      let members = getMembersResult.ok;
      let getRolesResult = await workspaceIam.get_roles();
      let roles = "ok" in getRolesResult ? getRolesResult.ok : [];

      let results = [];

      for (let member of members) {
        let role = roles.find((role) => role.rid === member.roleId);
        let getProfileResult = await accountManager.get_account(member.identity);
        let profile = "ok" in getProfileResult ? getProfileResult.ok : undefined;
        let name = profile ? profile.firstName + " " + profile.lastName : "Unknown";

        results.push({
          id: member.identity.toString(),
          name: name,
          role: role ? role.name : "Unknown",
        });
      }

      return setWorkspaceMembers(results);
    } else {
      let error = getMembersResult.err;
      console.error(error);
    }
  };

  const getFirstLetter = (text: string): string => {
    return text.charAt(0).toUpperCase();
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

  const deleteIdmember = async (idMember: string) => {
    if (!workspaceIam) return;

    setLoading(true);

    try {
      const memberId = Principal.fromText(idMember);
      const response = await workspaceIam.delete_access(memberId);

      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return;
      }

      getWorkspaceMembers();
    } catch (error) {
      console.error("error response", { error });
    } finally {
      setLoading(false);
      window.location.reload();
    }
  };

  const addMemberWorkspace = async (userId: string) => {
    if (!workspaceIam) return;

    setLoading(true);
    try {
      const memberId = Principal.fromText(userId);
      const response = await workspaceIam.create_access({
        identity: memberId,
        roleId: "Administrator",
        itype: { user: null },
      });

      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return;
      }

      getWorkspaceMembers();
    } catch (error) {
      console.error("error response", { error });
    } finally {
      setLoading(false);
      setShowModal(false);
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

  if (loadingAuth || workspaceId === undefined) {
    return (
      <div className="flex justify-center items-center h-screen">
        <div className="spinner-border animate-spin inline-block w-8 h-8 border-4 rounded-full" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }
  return (
    <WorkspaceLayout>
      <div className="flex flex-col w-full ">
        <div
          style={{ height: "calc(100vh - 64px)" }}
          className="container w-full flex flex-col justify-start items-end  bg-slate-100 h-full p-6 rounded-lg">
          <button
            className="bg-green-400 text-white px-8 py-2 rounded-lg mb-4 w-36"
            onClick={() => setShowModal(true)}>
            New
          </button>
          <div className="bg-white w-full shadow-md rounded-lg overflow-hidden ">
            <div className="grid grid-cols-3 bg-gray-200 p-4 text-gray-700 font-bold">
              <div>Name</div>
              <div>Role</div>
              <div>Action</div>
            </div>
            <div className="divide-y divide-gray-200">
              {workspaceMembers.map((item, index) => (
                <div key={index} className="grid grid-cols-3 p-4">
                  <div>
                    {item.name}
                    <span className="text-cyan-800 bg-gray-200 rounded-[5px] text-sm font-bold px-[5px] ml-[8px]">
                      OWNER
                    </span>
                  </div>
                  <div>{item.role}</div>
                  <div>
                    {item.id !== ownerId && (
                      <button
                        className="bg-red-500 text-white py-1 px-3 rounded-lg"
                        onClick={() => {
                          deleteIdmember(item.id);
                        }}
                        disabled={loading}>
                        {loading ? <LoadingSpinner /> : "Delete"}
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
        <Modal
          showModal={showModal}
          setShowModal={setShowModal}
          addMemberWorkspace={addMemberWorkspace}
          getListFindName={getListFindName}
          dataNameSearch={dataNameSearch}
          loading={loading}
        />
      </div>
    </WorkspaceLayout>
  );
}
