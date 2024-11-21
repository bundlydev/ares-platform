import { Principal } from "@dfinity/principal";
import { useRouter } from "next/router";
import { useEffect, useRef, useState } from "react";

import { useAuth, useCandidActor } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters";
import LoadingSpinner from "@app/components/LoadingSpinner";
import ModalApps from "@app/components/ModalApps";
import { useAuthGuard } from "@app/hooks/useGuard";

type WorkspaceData = {
  id: string;
  name: string;
};
type UsernameData = {
  id: string;
  username: string;
};

export default function WorkspaceAppsPage(): JSX.Element {
  const router = useRouter();
  const { currentIdentity } = useAuth();
  useAuthGuard({ isPrivate: true });
  const [showModal, setShowModal] = useState<boolean>(false);
  const [dataNameSearch, setDataNameSearch] = useState<UsernameData[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [isOpen, setIsOpen] = useState<boolean>(false);

  const [workspaceMembers, setWorkspaceMembers] = useState<WorkspaceData[]>([]);

  const workspaceRef = useRef<HTMLDivElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  let workspaceId = router.query["workspace-id"] as string;

  const accountManager = useCandidActor<CandidActors>(
    "accountManager",
    currentIdentity
  ) as CandidActors["accountManager"];

  const workspace = useCandidActor<CandidActors>("workspace", currentIdentity, {
    canisterId: workspaceId,
  }) as CandidActors["workspace"];

  useEffect(() => {
    getApps();
  }, []);

  const getApps = async () => {
    const getMembersResult = await workspace.iam_get_access_list({ filters: { itype: { app: null } } });
    if ("ok" in getMembersResult) {
      const NameList = getMembersResult.ok.map((item) => ({
        id: item.identity.toString(),
        name: item.identity.toString(),
      }));
      setWorkspaceMembers(NameList);
    } else {
      let error = getMembersResult.err;
      console.error(error);
    }
  };

  const deleteIdapp = async (idApp: string) => {
    if (!workspace) return;

    setLoading(true);

    try {
      const appId = Principal.fromText(idApp);
      const response = await workspace.iam_delete_access(appId);

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

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        menuRef.current &&
        !menuRef.current.contains(event.target as Node) &&
        workspaceRef.current &&
        !workspaceRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [menuRef, workspaceRef]);

  return (
    <div className="flex flex-col w-full mt-4">
      <div className="container w-full flex flex-col justify-start items-end  bg-slate-100 h-full p-6 rounded-lg">
        <button
          className="bg-green-400 text-white px-8 py-2 rounded-lg mb-4 w-36"
          onClick={() => setShowModal(true)}>
          New
        </button>
        <div className="bg-white w-full shadow-md rounded-lg overflow-hidden ">
          <div className="grid grid-cols-2 bg-gray-200 p-4 text-gray-700 font-bold">
            <div>Principal</div>
            <div>Action</div>
          </div>
          <div className="divide-y divide-gray-200">
            {workspaceMembers.map((item, index) => (
              <div key={index} className="grid grid-cols-2 p-4">
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
      <ModalApps
        getData={getApps}
        showModal={showModal}
        setShowModal={setShowModal}
      />
    </div>
  );
}
