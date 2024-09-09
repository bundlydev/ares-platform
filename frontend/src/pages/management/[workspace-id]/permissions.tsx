import { Principal } from "@dfinity/principal";
import { zodResolver } from "@hookform/resolvers/zod";
import { useRouter } from "next/router";
import { useContext, useEffect, useRef, useState } from "react";
import { SubmitHandler, useForm } from "react-hook-form";
import { z } from "zod";

import { useAuth, useCandidActor } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters";
import LoadingSpinner from "@app/components/LoadingSpinner";
import { AuthContext } from "@app/context/auth-context";
import { useAuthGuard } from "@app/hooks/useGuard";
import WorkspaceLayout from "@app/layouts/WorkspaceLayout";

type Workspace = {
  id: string;
  name: string;
};
type WorkspaceData = {
  action: string;
  description: string;
};
type UsernameData = {
  id: string;
  username: string;
};
type FormValues = {
  permission: string;
  description: string;
};
export default function ManagementPermissionsPage(): JSX.Element {
  const router = useRouter();
  const { currentIdentity } = useAuth();
  useAuthGuard({ isPrivate: true });
  const [showModal, setShowModal] = useState<boolean>(false);
  const [dataNameSearch, setDataNameSearch] = useState<UsernameData[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [workspaceIsOpen, setWorkspaceIsOpen] = useState<boolean>(false);
  const [permissionsList, setPermissionsList] = useState<WorkspaceData[]>([]);
  const { userManagementId } = useContext(AuthContext);
  const workspaceRef = useRef<HTMLDivElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  let workspaceId = router.query["workspace-id"] as string;

  const accountManager = useCandidActor<CandidActors>(
    "accountManager",
    currentIdentity
  ) as CandidActors["accountManager"];

  const workspaceIam = useCandidActor<CandidActors>("workspaceIam", currentIdentity, {
    canisterId: workspaceId,
  }) as CandidActors["workspaceIam"];

  const workspaceUser = useCandidActor<CandidActors>("workspaceUser", currentIdentity, {
    canisterId: userManagementId,
  }) as CandidActors["workspaceUser"];
  const formSchema = z.object({
    permission: z.string().min(1, "Permission is required"),
    description: z.string().min(1, "Description is required"),
  });
  useEffect(() => {
    getPermissions();
  }, []);

  const getPermissions = async () => {
    if (!workspaceUser) return;

    const getPermissionsResult = await workspaceUser.get_permissions();
    if ("ok" in getPermissionsResult) {
      const rolesOptions = getPermissionsResult.ok.map((permission: { action: any; description: any }) => ({
        action: permission.action,
        description: permission.description,
      }));
      setPermissionsList(rolesOptions);
    } else {
      let error = getPermissionsResult.err;
      console.error(error);
    }
  };

  const deleteIdapp = async (idApp: string) => {
    if (!workspaceUser) return;

    setLoading(true);

    try {
      const response = await workspaceUser.delete_permission(idApp);
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

  // Configuración de React Hook Form sin Yup
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(formSchema),
  });

  const onSubmit: SubmitHandler<FormValues> = async (data) => {
    if (!workspaceIam) return;
    setLoading(true);
    try {
      const response = await workspaceUser.create_permission({
        action: data.permission,
        description: data.description,
      });

      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) alert("User not authenticated");

        throw new Error("Error creating profile");
      }
      if ("ok" in response) {
        window.location.reload();
      }
    } catch (error) {
      console.error({ error });
    } finally {
      setLoading(false);
    }
  };

  return (
    <WorkspaceLayout>
      <div className="flex flex-col w-full">
        <span className="text-[34px] font-semibold">Permissions</span>
        <span className="text-[12px] font-medium">
          Create and manage Permissions for your applications.
        </span>
				<span className="text-[12px] font-medium">
				Permissions can be assigned to Roles or Users.
				</span>
				<span className="text-[16px] font-medium mt-4 mb-2">Add a permission</span>
        <form onSubmit={handleSubmit(onSubmit)} className="w-full flex flex-col">
          <div className="flex items-center space-x-4">
            <div>
              <input
                type="text"
                placeholder="Permission"
                {...register("permission", { required: "Permission is required" })}
                className={`border p-2 rounded ${errors.permission ? "border-red-500" : "border-gray-300"}`}
              />
              {errors.permission && <p className="text-red-500">{errors.permission.message}</p>}
            </div>
            <div>
              <input
                type="text"
                placeholder="Description"
                {...register("description", {
                  required: "Description is required",
                })}
                className={`border p-2 rounded ${errors.description ? "border-red-500" : "border-gray-300"}`}
              />
              {errors.description && <p className="text-red-500">{errors.description.message}</p>}
            </div>
            <button type="submit" className="bg-green-400 text-white px-6 py-2 rounded">
              {loading ? <LoadingSpinner /> : "+ Add"}
            </button>
          </div>
        </form>

        <span className="text-[16px] font-medium mb-3 mt-6">List of permission</span>
        <div className="bg-white w-full shadow-md rounded-lg overflow-hidden ">
          <div className="grid grid-cols-3 bg-gray-200 p-4 text-gray-700 font-bold">
            <div>Permission</div>
            <div>Description</div>
            <div>Action</div>
          </div>
          <div className="divide-y divide-gray-200">
            {permissionsList.map((item, index) => (
              <div key={index} className="grid grid-cols-3 p-4">
                <div>{item.action}</div>
                <div>{item.description}</div>
                <div>
                  <button
                    className="bg-red-500 text-white py-1 px-3 rounded-lg"
                    onClick={() => {
                      deleteIdapp(item.action);
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
    </WorkspaceLayout>
  );
}
