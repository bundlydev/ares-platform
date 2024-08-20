import { Principal } from "@dfinity/principal";
import React, { useContext, useEffect, useRef, useState } from "react";

import { LogoutButton, useAuth, useCandidActor, useIdentities } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters/index";
import { useAuthGuard } from "@app/hooks/useGuard";

import LoadingSpinner from "../components/LoadingSpinner";
import Menu from "../components/Menu";
import ModalApps from "../components/ModalApps";
import SelectWorkspace from "../components/SelectWorkspace";
import { AuthContext } from "../context/auth-context";
import { useProfile } from "../hooks/useProfile";
import { useWorkspaces } from "../hooks/useWorkspaces";

export default function Apps() {
  type Workspace = {
    id: string;
    name: string;
  };
  type WorkspaceData = {
    id: string;
    name: string;
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

  const backofficeGateway = useCandidActor<CandidActors>(
    "backofficeGateway",
    currentIdentity
  ) as CandidActors["backofficeGateway"];

  const workspaceActor = workspaceId
    ? (useCandidActor<CandidActors>("workspace", currentIdentity, {
        canisterId: workspaceId,
      }) as CandidActors["workspace"])
    : null;

  // const workspaceActor = useCandidActor<CandidActors>("workspace", currentIdentity, {
  //   canisterId: workspaceId,
  // }) as CandidActors["workspace"];

  useEffect(() => {
    getApps();
  }, [workspaceId]);

  const getApps = async () => {
    // TODO: Should I catch errors here?
    if (!workspaceActor) return;

    const getMembersResult = await workspaceActor.getApps();
    if ("ok" in getMembersResult) {
			const NameList = getMembersResult.ok.map((item: { principal: { toString: () => any; }; name: any; }) => ({
				id: item.principal.toString(),
				name: item.name,
			}));
			setWorkspaceMembers(NameList)
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

  const deleteIdapp = async (idApp: string) => {
    if (!workspaceActor) return;

    setLoading(true);

    try {
      const appId = Principal.fromText(idApp);
      const response = await workspaceActor.removeApp(appId);

      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return;
      }

      getApps();
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

      getApps();
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
          {workspaces && <SelectWorkspace />}
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
        <Menu />
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
              <div>Action</div>
            </div>
            <div className="divide-y divide-gray-200">
              {workspaceMembers.map((item, index) => (
                <div key={index} className="grid grid-cols-3 p-4">
                  <div>{item.name}</div>
                  <div>
                      <button
                        className="bg-red-500 text-white py-1 px-3 rounded-lg"
                        onClick={() => {
                          deleteIdapp(item.id);
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
      </div>
      <ModalApps
        showModal={showModal}
        setShowModal={setShowModal}
        addMemberWorkspace={addMemberWorkspace}
        getListFindName={getListFindName}
        dataNameSearch={dataNameSearch}
      />
    </div>
  );
}
