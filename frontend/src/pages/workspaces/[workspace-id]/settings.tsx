import { Principal } from "@dfinity/principal";
import { useRouter } from "next/router";
import { useState } from "react";

import { useAuth, useCandidActor } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters";
import LoadingSpinner from "@app/components/LoadingSpinner";
import ModalDelete from "@app/components/ModalDelete";
import { useAuthGuard } from "@app/hooks/useGuard";
import { useWorkspaces } from "@app/hooks/useWorkspaces";
import WorkspaceLayout from "@app/layouts/WorkspaceLayout";

type WorkspaceSettingsPageProps = {};

export default function WorkspaceSettingsPage(props: WorkspaceSettingsPageProps): JSX.Element {
  const loadingAuth = useAuthGuard({ isPrivate: true });
  const router = useRouter();
  const { currentIdentity } = useAuth();
  const workspaces = useWorkspaces();

  const [showModalDelete, setShowModalDelete] = useState<boolean>(false);
  const [deleteInProgress, setDeleteInProgress] = useState<boolean>(false);

  let workspaceId = router.query["workspace-id"] as string;

  const workspaceOrchestrator = useCandidActor<CandidActors>(
    "workspaceOrchestrator",
    currentIdentity
  ) as CandidActors["workspaceOrchestrator"];

  const workspaceIam = useCandidActor<CandidActors>("workspaceIam", currentIdentity, {
    canisterId: workspaceId,
  }) as CandidActors["workspaceIam"];

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
        else console.log(response, "pagesettingsError fetching profile");
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
    <WorkspaceLayout>
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
    </WorkspaceLayout>
  );
}
