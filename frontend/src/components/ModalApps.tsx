import { Principal } from "@dfinity/principal";
import React, { ChangeEvent, FC, useContext, useEffect, useState } from "react";
import { SubmitHandler, useForm } from "react-hook-form";

import { LogoutButton, useAuth, useCandidActor, useIdentities } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters/index";

import { AuthContext } from "../context/auth-context";
import LoadingSpinner from "./LoadingSpinner";

interface NameData {
  id: string;
  username: string;
}

type FormValues = {
  name: string;
};

interface ModalProps {
  showModal: boolean;
  setShowModal: (show: boolean) => void;
  addMemberWorkspace: (userId: string) => void;
  getListFindName: (nameText: string) => void;
  dataNameSearch: NameData[];
}

const ModalApps: FC<ModalProps> = ({
  showModal,
  setShowModal,
  addMemberWorkspace,
  getListFindName,
  dataNameSearch,
}) => {
  const { currentIdentity } = useAuth();
  const [inputValue, setInputValue] = useState<string>("");
  const { workspaceId } = useContext(AuthContext);
  const [loading, setLoading] = useState(false);
  const [inputValueId, setInputValueId] = useState<string>("");
  const [selectedNames, setSelectedNames] = useState<NameData[]>([]);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>();

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setInputValue(value);

    if (value.length >= 3) {
      getListFindName(value);
    } else {
      setSelectedNames([]);
    }
  };

  const handleSelect = (id: string, username: string) => {
    setInputValue(username);
    setInputValueId(id);
    setSelectedNames((prevSelectedNames) => [...prevSelectedNames, { id, username }]);
  };

  const handleAdd = () => {
    addMemberWorkspace(inputValueId);
    setInputValue("");
    setInputValueId("");
  };
  const workspaceIam = workspaceId
    ? (useCandidActor<CandidActors>("workspaceIam", currentIdentity, {
        canisterId: workspaceId,
      }) as CandidActors["workspaceIam"])
    : null;
  const filteredDataNameSearch = dataNameSearch.filter(
    (name) => !selectedNames.some((selected) => selected.id === name.id)
  );

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
      const number = "bd3sg-teaaa-aaaaa-qaaba-cai";
      const value = Principal.fromText(number);
      const response = await workspaceIam.create_access(value, data.name, { app: null });
      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) alert("User not authenticated");

        throw new Error("Error creating profile");
      }
      if ("ok" in response) {
        window.location.href = "/apps";
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
            <input
              {...register("name", { required: "Name is required" })}
              type="text"
              placeholder="Type name"
              className="h-10 w-11/12 rounded-lg border border-gray-300 px-2"
            />
            <span className="text-red-500 h-2">{errors.name && "Name is required"}</span>
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
