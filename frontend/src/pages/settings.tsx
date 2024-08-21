import { Principal } from "@dfinity/principal";
import React, { useContext, useEffect, useRef, useState } from "react";

import { LogoutButton, useAuth, useCandidActor, useIdentities } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters/index";
import { useAuthGuard } from "@app/hooks/useGuard";

import LoadingSpinner from "../components/LoadingSpinner";
import Menu from "../components/Menu";
import ModalDelete from "../components/ModalDelete";
import SelectWorkspace from "../components/SelectWorkspace";
import { AuthContext } from "../context/auth-context";
import { useProfile } from "../hooks/useProfile";
import { useWorkspaces } from "../hooks/useWorkspaces";

export default function Settings() {
  type Workspace = {
    id: string;
    name: string;
  };

  const { currentIdentity } = useAuth();
  const { workspaceId } = useContext(AuthContext);
  const [showModalDelete, setShowModalDelete] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(false);
  const [deleteInProgress, setDeleteInProgress] = useState<boolean>(false);

  const workspaces = useWorkspaces();
  const profiles = useProfile();
  const identity = useIdentities();
  const loadingAuth = useAuthGuard({ isPrivate: true });

  const workspaceRef = useRef<HTMLDivElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  const workspaceOrchestrator = useCandidActor<CandidActors>(
    "workspaceOrchestrator",
    currentIdentity
  ) as CandidActors["workspaceOrchestrator"];

  const findWorkspaceName = () => {
    const workspace = workspaces.find((workspace) => workspace.id === workspaceId);
    return workspace ? workspace.name : "";
  };

  const deleteIdworkspace = async (idWorkspace: string) => {
    try {
      setDeleteInProgress(true);
      const workspaceId = Principal.fromText(idWorkspace);
      const response = await workspaceOrchestrator.delete_workspace(workspaceId);

      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
        return;
      }
      setShowModalDelete(false);
      window.location.reload();
    } catch (error) {
      console.error("error response", { error });
    } finally {
      setDeleteInProgress(false);
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
    <div className="flex flex-col w-full">
      <div
        style={{ height: "calc(100vh - 64px)" }}
        className="container w-full flex flex-col justify-start items-start bg-slate-100 h-full p-6 rounded-lg">
        <span className="font-bold text-4xl">Settings workspace</span>
        <div className="flex items-end h-11 gap-4">
          <span className="font-medium text-xl">My workspace: </span>
          {findWorkspaceName()}
          <button onClick={handleDelete} className="bg-red-500 text-white py-2 px-6 rounded-lg">
            Delete
          </button>
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
