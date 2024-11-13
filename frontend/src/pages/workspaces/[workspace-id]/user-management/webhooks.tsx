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

import useStore from "../../../../store/useStore";

type Workspace = {
  id: string;
  name: string;
};
type WorkspaceData = {
  ref: string;
  name: string;
  createdBy: string;
  createdAt: Date;
};
type UsernameData = {
  id: string;
  username: string;
};
type FormValues = {
  webhook: string;
  name: string;
};
export default function WebhooksPage(): JSX.Element {
  const router = useRouter();
  const { currentIdentity } = useAuth();
  const { userIAMid, workspaceRefId } = useStore();
  const { userMid } = useStore();
  useAuthGuard({ isPrivate: true });
  const [showModal, setShowModal] = useState<boolean>(false);
  const [dataNameSearch, setDataNameSearch] = useState<UsernameData[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [workspaceIsOpen, setWorkspaceIsOpen] = useState<boolean>(false);
  const [webhooksList, setWebhooksList] = useState<WorkspaceData[]>([]);
  const { userManagementId } = useContext(AuthContext);
  const workspaceRef = useRef<HTMLDivElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  let workspaceId = router.query["workspace-id"] as string;

  const workspaceIam = useCandidActor<CandidActors>("workspace", currentIdentity, {
    canisterId: workspaceRefId,
  }) as CandidActors["workspace"];
  const workspaceUser = useCandidActor<CandidActors>("workspace", currentIdentity, {
    canisterId: workspaceRefId,
  }) as CandidActors["workspace"];
  const formSchema = z.object({
    webhook: z.string().min(1, "Webhook is required"),
    name: z.string().min(1, "Name is required"),
  });
  useEffect(() => {
    ;
    getWebhooks();
  }, []);

  const getWebhooks = async () => {
    if (!workspaceUser) return;

    const getWebhooksResult = await workspaceUser.webhooks_get_webhook_list();
    if ("ok" in getWebhooksResult) {
      const transformedWebhooks = getWebhooksResult.ok.map((webhook) => ({
        ref: webhook.ref.toString(),
        name: webhook.name,
        createdBy: webhook.createdBy.toString(), 
        createdAt: new Date(Number(webhook.createdAt) / 1e6),
      }));

      setWebhooksList(transformedWebhooks);
    }
  };

  const deleteIdapp = async (idApp: string) => {
    setLoading(true);
    try {
      const response = await workspaceUser.webhooks_remove_webhook(Principal.fromText(idApp));
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
      const response = await workspaceUser.webhooks_register_webhook({
        principal: Principal.fromText(data.webhook),
        name: data.name,
      });
      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) alert("User not authenticated");

        throw new Error("Error creating permissions");
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
  console.log(webhooksList, "-----webhooksList");
  return (
    <WorkspaceLayout>
      <div className="flex flex-col w-full">
        <span className="text-[34px] font-semibold">Webhookss</span>
        <span className="text-[12px] font-medium">Create and manage Permissions for your applications.</span>
        <span className="text-[12px] font-medium">Permissions can be assigned to Roles or Users.</span>
        <span className="text-[16px] font-medium mt-4 mb-2">Add a webhooks</span>
        <form onSubmit={handleSubmit(onSubmit)} className="w-full flex flex-col">
          <div className="flex items-center space-x-4">
            <div>
              <input
                type="text"
                placeholder="Webhook"
                {...register("webhook", { required: "Webhook is required" })}
                className={`border p-2 rounded ${errors.webhook ? "border-red-500" : "border-gray-300"}`}
              />
              {errors.webhook && <p className="text-red-500">{errors.webhook.message}</p>}
            </div>
            <div>
              <input
                type="text"
                placeholder="Name"
                {...register("name", {
                  required: "Name is required",
                })}
                className={`border p-2 rounded ${errors.name ? "border-red-500" : "border-gray-300"}`}
              />
              {errors.name && <p className="text-red-500">{errors.name.message}</p>}
            </div>
            <button type="submit" className="bg-green-400 text-white px-6 py-2 rounded">
              {loading ? <LoadingSpinner /> : "+ Add"}
            </button>
          </div>
        </form>

        <span className="text-[16px] font-medium mb-3 mt-6">List of webhooks</span>
        <div className="bg-white w-full shadow-md rounded-lg overflow-hidden ">
          <div className="grid grid-cols-5 bg-gray-200 p-4 text-gray-700 font-bold">
            <div>Webhook</div>
            <div>Name</div>
            <div>Created by</div>
            <div>Created at</div>
            <div>Action</div>
          </div>
          <div className="divide-y divide-gray-200">
            {webhooksList.map((item, index) => (
              <div key={index} className="grid grid-cols-5 p-4">
                <div>{item.ref.toString()}</div>
                <div>{item.name}</div>
                <div>{item.createdBy.toString()}</div>
                <div>{new Date(Number(item.createdAt) / 1e6).toLocaleString()}</div>
                <div>
                  <button
                    className="bg-red-500 text-white py-1 px-3 rounded-lg"
                    onClick={() => {
                      deleteIdapp(item.ref);
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
