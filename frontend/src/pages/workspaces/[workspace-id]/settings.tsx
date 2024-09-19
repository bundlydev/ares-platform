import { Principal } from "@dfinity/principal";
import { useRouter } from "next/router";
import { useState } from "react";

import { useAuth, useCandidActor } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters";
import LoadingSpinner from "@app/components/LoadingSpinner";
import ModalDelete from "@app/components/ModalDelete";
import WorkspaceAppsPage from "@app/components/apps";
import WorkspaceRolesPage from "@app/components/roles";
import WorkspaceUsersPage from "@app/components/users";
import { useAuthGuard } from "@app/hooks/useGuard";
import { useWorkspaces } from "@app/hooks/useWorkspaces";
import WorkspaceLayout from "@app/layouts/WorkspaceLayout";
import useStore from "@app/store/useStore";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@app/ui/components/tabs";

type WorkspaceSettingsPageProps = {};

export default function WorkspaceSettingsPage(props: WorkspaceSettingsPageProps): JSX.Element {
  const { userIAMid } = useStore();
  const router = useRouter();
  const { currentIdentity } = useAuth();
  const workspaces = useWorkspaces();
  useAuthGuard({ isPrivate: true });
  const [showModalDelete, setShowModalDelete] = useState<boolean>(false);
  const [deleteInProgress, setDeleteInProgress] = useState<boolean>(false);

  let workspaceId = router.query["workspace-id"] as string;
  const workspaceOrchestrator = useCandidActor<CandidActors>(
    "workspaceOrchestrator",
    currentIdentity
  ) as CandidActors["workspaceOrchestrator"];

  const workspaceIam = useCandidActor<CandidActors>("workspaceIam", currentIdentity, {
    canisterId: userIAMid,
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

  return (
    <WorkspaceLayout>
      <div className="flex flex-col w-full">
        <Tabs defaultValue="settings" className="w-full">
          <TabsList className="grid w-full grid-cols-4 bg-gray-100 p-2 rounded-lg">
            <TabsTrigger
              value="settings"
              className="px-4 py-2 text-gray-700 font-semibold hover:bg-gray-200 focus:ring-2 focus:ring-blue-500 rounded data-[state=active]:ring-blue-500 data-[state=active]:text-blue-700">
              Settings
            </TabsTrigger>
            <TabsTrigger
              value="users"
              className="px-4 py-2 text-gray-700 font-semibold hover:bg-gray-200 focus:ring-2 focus:ring-blue-500 rounded data-[state=active]:ring-blue-500 data-[state=active]:text-blue-700">
              Users
            </TabsTrigger>
            <TabsTrigger
              value="apps"
              className="px-4 py-2 text-gray-700 font-semibold hover:bg-gray-200 focus:ring-2 focus:ring-blue-500 rounded data-[state=active]:ring-blue-500 data-[state=active]:text-blue-700">
              Apps
            </TabsTrigger>
            <TabsTrigger
              value="roles"
              className="px-4 py-2 text-gray-700 font-semibold hover:bg-gray-200 focus:ring-2 focus:ring-blue-500 rounded data-[state=active]:ring-blue-500 data-[state=active]:text-blue-700">
              Roles
            </TabsTrigger>
          </TabsList>
          <TabsContent value="settings" className="p-6 rounded-lg">
            <div className="container w-full flex flex-col justify-start items-start h-full p-6 rounded-lg">
              <span className="font-bold text-4xl">Settings workspace</span>
              <div className="flex items-end h-11 gap-4">
                <span className="font-medium text-xl">My workspace: </span>
                {findWorkspaceName()}
                <button onClick={handleDelete} className="bg-red-500 text-white py-2 px-6 rounded-lg">
                  Delete
                </button>
              </div>
            </div>
          </TabsContent>
          <TabsContent value="users">
            <WorkspaceUsersPage />
          </TabsContent>
          <TabsContent value="apps">
            <WorkspaceAppsPage />
          </TabsContent>
          <TabsContent value="roles">
            <WorkspaceRolesPage />
          </TabsContent>
        </Tabs>

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
