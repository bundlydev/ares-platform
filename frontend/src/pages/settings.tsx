import React, { useContext, useEffect, useRef, useState } from "react";
import { Principal } from "@dfinity/principal";
import { LogoutButton, useAuth, useCandidActor, useIdentities } from "@bundly/ares-react";
import { CandidActors } from "@app/canisters/index";
import { useAuthGuard } from "@app/hooks/useGuard";
import LoadingSpinner from "../components/LoadingSpinner";
import Menu from "../components/Menu";
import SelectWorkspace from "../components/SelectWorkspace";
import { AuthContext } from "../context/auth-context";
import { useProfile } from "../hooks/useProfile";
import { useWorkspaces } from "../hooks/useWorkspaces";
import ModalDelete from "../components/ModalDelete";

export default function Settings() {
  type Workspace = {
    id: string;
    name: string;
  };

  const { currentIdentity } = useAuth();
  const { workspaceId } = useContext(AuthContext);
  const [showModalDelete, setShowModalDelete] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(false);
  const [deleteInProgress, setDeleteInProgress] = useState<boolean>(false); // Nuevo estado para el loading del delete

  const workspaces = useWorkspaces();
  const profiles = useProfile();
  const identity = useIdentities();
  const loadingAuth = useAuthGuard({ isPrivate: true });

  const workspaceRef = useRef<HTMLDivElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  const backofficeGateway = useCandidActor<CandidActors>(
    "backofficeGateway",
    currentIdentity
  ) as CandidActors["backofficeGateway"];

  const findWorkspaceName = () => {
    const workspace = workspaces.find((workspace) => workspace.id === workspaceId);
    return workspace ? workspace.name : "";
  };

  const deleteIdworkspace = async (idWorkspace: string) => {
    try {
      setDeleteInProgress(true); // Iniciar el loading específico para el delete
      const workspaceId = Principal.fromText(idWorkspace);
      const response = await backofficeGateway.deleteWorkspace(workspaceId);

      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return;
      }
      // Si la petición fue exitosa, cerrar el modal y recargar la página
      setShowModalDelete(false);
      window.location.reload();
    } catch (error) {
      console.error("error response", { error });
    } finally {
      setDeleteInProgress(false); // Detener el loading específico para el delete
    }
  };

  const handleDelete = () => {
    setShowModalDelete(true);
  };

  const handleConfirmDelete = () => {
    deleteIdworkspace(workspaceId!);
  };

  if (loadingAuth || workspaceId === undefined) {
    return (
      <div className="flex justify-center items-center h-screen">
        <LoadingSpinner />
      </div>
    );
  }

  return (
    <div className="flex flex-col">
      <div className="flex h-16 bg-cyan-950 items-center justify-between px-2">
        <div ref={workspaceRef} className="flex w-1/4 justify-around">
          {profiles && (
            <div className="flex bg-cyan-600 rounded-full h-9 w-9 items-center justify-center">
              <span className="text-white">{profiles?.firstName.charAt(0).toUpperCase()}</span>
            </div>
          )}
          {workspaces && <SelectWorkspace />}
        </div>
      </div>
      <div className="flex items-start">
        <Menu />
        <div
          style={{ height: "calc(100vh - 64px)" }}
          className="container w-full flex flex-col justify-start items-start bg-slate-100 h-full p-6 rounded-lg"
        >
          <span className="font-bold text-4xl">Settings workspace</span>
          <div className="flex items-end h-11 gap-4">
            <span className="font-medium text-xl">My workspace: </span>
            {findWorkspaceName()}
            <button onClick={handleDelete} className="bg-red-500 text-white py-2 px-6 rounded-lg">
              Delete
            </button>
          </div>
        </div>
      </div>
      <ModalDelete
        showModalDelete={showModalDelete}
        setShowModalDelete={setShowModalDelete}
        deleteItem={findWorkspaceName()}
        onConfirmDelete={handleConfirmDelete}
      />
      {deleteInProgress && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 z-50">
          <LoadingSpinner />
        </div>
      )}
    </div>
  );
}
