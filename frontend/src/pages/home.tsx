import { Principal } from "@dfinity/principal";
import React, { useEffect, useRef, useState } from "react";
import { LogoutButton, useAuth, useCandidActor, useIdentities } from "@bundly/ares-react";
import { CandidActors } from "@app/canisters/index";
import { useAuthGuard } from "@app/hooks/useGuard";
import Modal from "../components/Modal";
import ModalDelete from "../components/ModalDelete";
import SelectWorkspace from "../components/SelectWorkspace";
import { useProfile } from "../hooks/useProfile";
import { useWorkspace } from "../hooks/useWorkspace";

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

  const { isAuthenticated, currentIdentity } = useAuth();
  const backofficeGateway = useCandidActor<CandidActors>(
    "backofficeGateway",
    currentIdentity
  ) as CandidActors["backofficeGateway"];
  const Name = "Christian Cadena";
  const [showModal, setShowModal] = useState<boolean>(false);
  const [showModalDelete, setShowModalDelete] = useState<boolean>(false);
  const [deleteItem, setDeleteItem] = useState<string>("");
  const [myworkspaces, setMyworkspace] = useState<Workspace[]>([]);
  const [idDataworkspaces, setIdDataworkspaces] = useState<string>("");
  const [dataNameSearch, setDataNameSearch] = useState<UsernameData[]>([]);
  const [dataworkspaces, setDataworkspaces] = useState<WorkspaceData[]>([]);
  const workspaces = useWorkspace();
  const profiles = useProfile();
  const [items, setItems] = useState<string[]>(["Juan Pérez", "María López"]);
  const hasFetchedWorkspaces = useRef(false);
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const identity = useIdentities();
  const loading = useAuthGuard({ isPrivate: true });

  const getFirstLetter = (text: string): string => {
    return text.charAt(0).toUpperCase();
  };

  async function getWorkspaceList() {
    if (!workspaces || workspaces.length === 0) {
      return;
    }

    try {
      const promises = workspaces.map(async (workspace) => {
        const workspaceId = Principal.fromText(workspace.id);
        const response = await backofficeGateway.getWorkspaceInfo(workspaceId);
        if ("err" in response) {
          if ("userNotAuthenticated" in response.err) {
            console.log("User not authenticated");
          } else {
            console.log("Error fetching profile");
          }
          return null; // Retornar null en caso de error
        }

        const profile = "ok" in response ? response.ok : undefined;
        if ("ok" in response) {
          const profile = response.ok;
          if (profile) {
            return { id: profile.id.toString(), name: profile.name };
          }
        }
      });

      const results = await Promise.all(promises);
      const validResults = results.filter((result) => result !== null);
      setMyworkspace(validResults as Workspace[]);
    } catch (error) {
      console.error("error response", { error });
    }
  }

  useEffect(() => {
    if (!hasFetchedWorkspaces.current) {
      getWorkspaceList();
      hasFetchedWorkspaces.current = true; // Marcar como ejecutada
    }
  }, [currentIdentity, workspaces]);

  const getList = async (idWorkspace: string) => {
    setIdDataworkspaces(idWorkspace);
    try {
      const workspaceId = Principal.fromText(idWorkspace); // Convertir `id` a `Principal`
      const response = await backofficeGateway.getWorkspaceMembers(workspaceId);
      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return; // No continuar si hay error
      }
      const list = "ok" in response ? response.ok : undefined;
      if (list) {
        // Mapea `list` a un nuevo formato
        const newWorkspaceList = list.map(
          (member: { id: { toString: () => any }; name: any; role: { name: any } }) => ({
            id: member.id.toString(),
            name: member.name,
            role: member.role.name,
          })
        );

        setDataworkspaces(newWorkspaceList);
      }
      console.log(list, "mi lista");
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
        return; // No continuar si hay error
      }
      const listName = "ok" in response ? response.ok : undefined;
      if (listName) {
        // Mapea `list` a un nuevo formato
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
    try {
      const workspaceId = Principal.fromText(idDataworkspaces);
      const memberId = Principal.fromText(idMember);
      const response = await backofficeGateway.removeWorkspaceMember(workspaceId, memberId);
      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return; // No continuar si hay error
      }
      const member = "ok" in response ? response.ok : undefined;
      if (member) getList(idDataworkspaces);
    } catch (error) {
      console.error("error response", { error });
    }
  };

  const addMemberWorkspace = async (userId: string) => {
    try {
      const workspaceId = Principal.fromText(idDataworkspaces);
      const memberId = Principal.fromText(userId);
      const response = await backofficeGateway.addWorkspaceMember(workspaceId, memberId, BigInt(2));
      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return; // No continuar si hay error
      }
      if ("ok" in response) {
        const member = response.ok;
        if (member) {
          getList(idDataworkspaces);
        }
      }
    } catch (error) {
      console.error("error response", { error });
    }
  };

  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  const handleToggle = () => {
    setIsOpen(!isOpen);
  };

  // Cierra el menú si se hace clic fuera de él
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [menuRef]);

  if (loading) {
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
        <div className="flex w-1/4 justify-around">
          {profiles && (
            <div className="flex bg-cyan-600 rounded-full h-9 w-9 items-center justify-center">
              <span className="text-white">{getFirstLetter(profiles?.firstName)}</span>
            </div>
          )}
          {hasFetchedWorkspaces.current && <SelectWorkspace myworkspaces={myworkspaces} getList={getList} />}
        </div>
        {profiles && (
          <div className="relative inline-block text-left" ref={menuRef}>
            <div
              className="flex bg-cyan-600 rounded-full h-9 w-9 items-center justify-center cursor-pointer"
              onClick={handleToggle}
            >
              <span className="text-white">
                {getFirstLetter(profiles?.firstName)}
              </span>
            </div>
            {isOpen && identity.length > 0 && (
              <div className="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5">
                <div className="py-1" role="menu" aria-orientation="vertical" aria-labelledby="options-menu">
                  <LogoutButton 
                    identity={identity[0].identity} 
                    style={{color: 'red', fontSize: '18px',fontWeight: 500}}
                    role="menuitem"
                  />
                </div>
              </div>
            )}
          </div>
        )}
      </div>
      <div className="flex">
        <div className="container mx-auto mt-10 flex flex-col justify-end items-end">
          <button
            className="bg-green-400 text-white px-8 py-2 rounded-lg mb-4 w-36"
            onClick={() => setShowModal(true)}>
            New
          </button>
          <div className="bg-white shadow-md rounded-lg overflow-hidden w-10/12">
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
                    <button
                      className="bg-red-500 text-white py-1 px-3 rounded-lg"
                      onClick={() => {
                        deleteIdmember(item.id);
                      }}>
                      Eliminar
                    </button>
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
      />
      <ModalDelete
        showModalDelete={showModalDelete}
        setShowModalDelete={setShowModalDelete}
        deleteItem={deleteItem}
      />
    </div>
  );
}
