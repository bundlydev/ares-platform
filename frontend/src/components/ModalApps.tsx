import { Principal } from "@dfinity/principal";
import { zodResolver } from "@hookform/resolvers/zod";
import { useRouter } from "next/router";
import React, { ChangeEvent, FC, useEffect, useState } from "react";
import { SubmitHandler, useForm } from "react-hook-form";
import { z } from "zod";

import { useAuth, useCandidActor } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters/index";

import LoadingSpinner from "./LoadingSpinner";

interface NameData {
  id: string;
  username: string;
}

interface RoleData {
  label: string;
  value: string;
}

type FormValues = {
  name: string;
  role: string;
};

const formSchema = z.object({
  name: z
    .string()
    .min(1, "Canister Principal is required")
    .refine(
      (val) => {
        try {
          Principal.fromText(val);
          return true;
        } catch {
          return false;
        }
      },
      {
        message: "Type Canister Principal",
      }
    ),
  role: z.string().min(1, "Role is required"),
});

interface ModalProps {
  showModal: boolean;
  setShowModal: (show: boolean) => void;
  getData: any;
}

const ModalApps: FC<ModalProps> = ({ showModal, setShowModal, getData }) => {
  const { currentIdentity } = useAuth();
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [selectedRoles, setSelectedRoles] = useState<RoleData[]>([]);

  let workspaceId = router.query["workspace-id"] as string;

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(formSchema),
  });

  const workspace = useCandidActor<CandidActors>("workspace", currentIdentity, {
    canisterId: workspaceId,
  }) as CandidActors["workspace"];

  const getRoles = async () => {
    if (!workspace) return;

    const getRolesResult = await workspace.iam_get_roles();
    if ("ok" in getRolesResult) {
      const rolesOptions = getRolesResult.ok.map((role) => ({
        label: role.name,
        value: role.name,
      }));
      setSelectedRoles(rolesOptions);
    } else {
      let error = getRolesResult.err;
      console.error(error);
    }
  };

  useEffect(() => {
    getRoles();
  }, []);

  if (!showModal) {
    return null;
  }

  const onSubmit: SubmitHandler<FormValues> = async (data) => {
    if (!workspace) return;
    setLoading(true);
    try {
      const value = Principal.fromText(data.name);
      const response = await workspace.iam_create_access({
        identity: value,
        roleId: data.role,
        itype: { app: null },
      });

      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) alert("User not authenticated");

        throw new Error("Error creating profile");
      }
      if ("ok" in response) {
        setShowModal(false);
        getData();
      }
    } catch (error) {
      console.error({ error });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 flex justify-center items-center">
      <div className="bg-white p-6 rounded shadow-lg w-1/3">
        <form className="flex flex-col gap-y-6" onSubmit={handleSubmit(onSubmit)}>
          <h2 className="text-xl mb-4">Add Apps</h2>
          <div className="flex flex-col">
            <label htmlFor="name" className="text-gray-700 font-semibold">
              Canister Principal
            </label>
            <input
              {...register("name")}
              id="name"
              type="text"
              placeholder="Type Canister Principal"
              className="h-10 w-full rounded-lg border border-gray-300 px-2"
            />
            <span className="text-red-500 h-2">{errors.name?.message}</span>
          </div>
          <div className="flex flex-col">
            <label htmlFor="role" className="text-gray-700 font-semibold">
              Role
            </label>
            <select
              {...register("role")}
              id="role"
              className="bg-white border w-full border-gray-300 mt-2 text-cyan-950 h-[40px] px-2 py-1 rounded-md focus:outline-none focus:ring-2 focus:ring-cyan-600">
              <option value="">Select a role</option>
              {selectedRoles.map((role, index) => (
                <option key={index} value={role.value} className="text-cyan-950 bg-white hover:bg-gray-100">
                  {role.label}
                </option>
              ))}
            </select>
            <span className="text-red-500 h-2">{errors.role?.message}</span>
          </div>
          <div className="flex justify-end">
            <button
              className="bg-white text-gray px-4 py-2"
              onClick={() => setShowModal(false)}
              type="button">
              Cancel
            </button>
            <button className="bg-green-400 text-white px-8 py-2 rounded-lg mr-2" type="submit">
              {loading ? <LoadingSpinner /> : "Add"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ModalApps;
