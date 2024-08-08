import { Principal } from "@dfinity/principal";
import React, { useContext, useEffect, useRef, useState } from "react";

import { LogoutButton, useAuth, useCandidActor, useIdentities } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters/index";
import { useAuthGuard } from "@app/hooks/useGuard";

import LoadingSpinner from "../components/LoadingSpinner";
import Modal from "../components/Modal";
import ModalDelete from "../components/ModalDelete";
import SelectWorkspace from "../components/SelectWorkspace";
import { AuthContext } from "../context/auth-context";
import { useProfile } from "../hooks/useProfile";
import { useWorkspaces } from "../hooks/useWorkspaces";

export default function Home() {
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
  const { workspaceId } = useContext(AuthContext);
  const [showModal, setShowModal] = useState<boolean>(false);
  const [showModalDelete, setShowModalDelete] = useState<boolean>(false);
  const [deleteItem, setDeleteItem] = useState<string>("");
  const [myworkspaces, setMyworkspace] = useState<Workspace[]>([]);
  const [idDataworkspaces, setIdDataworkspaces] = useState<string>("");
  const [dataNameSearch, setDataNameSearch] = useState<UsernameData[]>([]);
  const [dataworkspaces, setDataworkspaces] = useState<WorkspaceData[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const workspaces = useWorkspaces();
  const profiles = useProfile();
  const [workspaceIsOpen, setWorkspaceIsOpen] = useState<boolean>(false);
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const identity = useIdentities();
  const loadingAuth = useAuthGuard({ isPrivate: true });

  const workspaceRef = useRef<HTMLDivElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const hasFetchedWorkspaces = useRef(false);

  const backofficeGateway = useCandidActor<CandidActors>(
    "backofficeGateway",
    currentIdentity
  ) as CandidActors["backofficeGateway"];

  const workspaceActor = workspaceId
    ? (useCandidActor<CandidActors>("workspace", currentIdentity, {
        canisterId: workspaceId,
      }) as CandidActors["workspace"])
    : null;

  const getFirstLetter = (text: string): string => {
    return text.charAt(0).toUpperCase();
  };

  const getList = async (idWorkspace: string) => {
    if (!workspaceActor) return;
    setIdDataworkspaces(idWorkspace);
    try {
      const members = await workspaceActor.getMembers();
      const roles = await workspaceActor.getRoles();

      if ("err" in members) {
        if ("userNotAuthenticated" in members.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return;
      }

      if ("err" in roles) {
        if ("userNotAuthenticated" in roles.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return;
      }

      const memberList = members.ok;
      const roleList = roles.ok;

      if (memberList) {
        const newWorkspaceList = await Promise.all(
          memberList.map(async (member) => {
            let profileInfo = await backofficeGateway.getProfileById(member.id);

            let memberName = "Unknown";

            if ("ok" in profileInfo) {
              memberName = profileInfo.ok.username;
            }

            return {
              id: member.id.toString(),
              name: memberName,
              role: roleList.find((role) => role.id === member.roleId)?.name || "Unknown",
            };
          })
        );

        setDataworkspaces(newWorkspaceList);
      }
    } catch (error) {
      console.error("error response", { error });
    }
  };

  const getListFindName = async (nameText: string) => {
    try {
      const response = await backofficeGateway.findProfilesByUsernameChunk(nameText);
      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return;
      }
      const listName = "ok" in response ? response.ok : undefined;
      if (listName) {
        const searchNameList = listName.map((member: { id: { toString: () => any }; username: any }) => ({
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
    if (!workspaceActor) return;

    setLoading(true);

    try {
      const memberId = Principal.fromText(idMember);
      const response = await workspaceActor.removeMember(memberId);

      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return;
      }
      const member = "ok" in response ? response.ok : undefined;
      if (member) getList(idDataworkspaces);
    } catch (error) {
      console.error("error response", { error });
    } finally {
      setLoading(false);
      window.location.reload();
    }
  };

  const addMemberWorkspace = async (userId: string) => {
    if (!workspaceActor) return;

    setLoading(true);
    try {
      const memberId = Principal.fromText(userId);
      const response = await workspaceActor.addMember(memberId, BigInt(2));

      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return;
      }
      if ("ok" in response) {
        const member = response.ok;
        if (member) {
          getList(idDataworkspaces);
        }
      }
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
    <div className="flex flex-col">
      <div className="flex h-16 bg-cyan-950 items-center justify-between px-2">
        <div ref={workspaceRef} className="flex w-1/4 justify-around">
          {profiles && (
            <div className="flex bg-cyan-600 rounded-full h-9 w-9 items-center justify-center">
              <span className="text-white">{getFirstLetter(profiles?.firstName)}</span>
            </div>
          )}
          {workspaces && <SelectWorkspace myworkspaces={workspaces} getList={getList} />}
        </div>
        {profiles && (
          <div className="relative inline-block text-left" ref={menuRef}>
            <div
              className="flex bg-cyan-600 rounded-full h-9 w-9 items-center justify-center cursor-pointer"
              onClick={handleToggle}>
              <span className="text-white">{getFirstLetter(profiles?.firstName)}</span>
            </div>
            {isOpen && identity.length > 0 && (
              <div className="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5">
                <div role="menu" aria-orientation="vertical" aria-labelledby="options-menu">
                  <LogoutButton
                    identity={identity[0].identity}
                    style={{
                      display: "flex",
                      width: "100%",
                      justifyContent: "flex-start",
                      color: "red",
                      fontSize: "18px",
                      alignItems: "center",
                      fontWeight: 500,
                      padding: "10px 15px",
                      gap: "15px",
                    }}>
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      className="feather feather-log-out"
                      style={{ width: "24px", height: "24px" }}>
                      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                      <polyline points="16 17 21 12 16 7"></polyline>
                      <line x1="21" y1="12" x2="9" y2="12"></line>
                    </svg>
                    <span>Logout</span>
                  </LogoutButton>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
      <div className="flex items-start">
        <div
          style={{ height: "calc(100vh - 64px)" }}
          className="flex flex-col justify-start items-center bg-cyan-950 w-56 gap-10 pt-10">
          <div className="cursor-pointer w-48 h-12 rounded-lg flex justify-center items-center bg-slate-100 text-cyan-950 text-2xl font-semibold">
            IAM
          </div>
        </div>
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
              {dataworkspaces.map((item, index) => (
                <div key={index} className="grid grid-cols-3 p-4">
                  <div>{item.name}</div>
                  <div>{item.role}</div>
                  <div>
                    {item.role !== "Owner" && (
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
      </div>
      <Modal
        showModal={showModal}
        setShowModal={setShowModal}
        addMemberWorkspace={addMemberWorkspace}
        getListFindName={getListFindName}
        dataNameSearch={dataNameSearch}
        loading={loading}
      />
      <ModalDelete
        showModalDelete={showModalDelete}
        setShowModalDelete={setShowModalDelete}
        deleteItem={deleteItem}
      />
    </div>
  );
}
