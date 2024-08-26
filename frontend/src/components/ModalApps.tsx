import { Principal } from "@dfinity/principal";
import { zodResolver } from "@hookform/resolvers/zod";
import React, { ChangeEvent, FC, useContext, useEffect, useState } from "react";
import { SubmitHandler, useForm } from "react-hook-form";
import { z } from "zod";

import { useAuth, useCandidActor } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters/index";

import { AuthContext } from "../context/auth-context";
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

// Define el esquema de validación de Zod
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
  getListFindName: (nameText: string) => void;
  dataNameSearch: NameData[];
}

const ModalApps: FC<ModalProps> = ({ showModal, setShowModal, getListFindName, dataNameSearch }) => {
  const { currentIdentity } = useAuth();
  const [inputValue, setInputValue] = useState<string>("");
  const { workspaceId } = useContext(AuthContext);
  const [loading, setLoading] = useState(false);
  const [inputValueId, setInputValueId] = useState<string>("");
  const [selectedNames, setSelectedNames] = useState<NameData[]>([]);
  const [selectedRoles, setSelectedRoles] = useState<RoleData[]>([]);

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(formSchema), // Utiliza zodResolver con el esquema de Zod
  });

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setInputValue(value);

    if (value.length >= 3) {
      getListFindName(value);
    } else {
      setSelectedNames([]);
    }
  };

  const workspaceIam = workspaceId
    ? (useCandidActor<CandidActors>("workspaceIam", currentIdentity, {
        canisterId: workspaceId,
      }) as CandidActors["workspaceIam"])
    : null;

  const filteredDataNameSearch = dataNameSearch.filter(
    (name) => !selectedNames.some((selected) => selected.id === name.id)
  );

  const getRoles = async () => {
    if (!workspaceIam) return;

    const getRolesResult = await workspaceIam.get_roles();
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

  useEffect(() => {
    if (inputValue === "") {
      setSelectedNames([]);
    }
  }, [inputValue]);

  if (!showModal) {
    return null;
  }

  const onSubmit: SubmitHandler<FormValues> = async (data) => {
    if (!workspaceIam) return;
    setLoading(true);
    try {
      const value = Principal.fromText(data.name); // Ya validado por Zod, no es necesario un try-catch aquí
      const response = await workspaceIam.create_access({
        identity: value,
        roleId: data.role,
        itype: { app: null },
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
