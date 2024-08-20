import { useRouter } from "next/router";
import React, { useState } from "react";
import { SubmitHandler, useForm } from "react-hook-form";

import { useAuth, useCandidActor } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters";
import { useAuthGuard } from "@app/hooks/useGuard";

import Modal from "../components/Modal";
import SelectWorkspace from "../components/SelectWorkspace";

type FormValues = {
  name: string;
};

function Workspace() {
  const { isAuthenticated, currentIdentity, changeCurrentIdentity } = useAuth();
  useAuthGuard({ isPrivate: true });
  const backofficeGateway = useCandidActor<CandidActors>(
    "backofficeGateway",
    currentIdentity
  ) as CandidActors["backofficeGateway"];
  const [image, setImage] = useState<File | null>(null);
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>();

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setImage(e.target.files[0]);
    }
  };

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      setImage(e.dataTransfer.files[0]);
    }
  };

  const handleDragOver = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
  };

  const onSubmit: SubmitHandler<FormValues> = async (data) => {
    setLoading(true);
    try {
      const response = await backofficeGateway.createWorkspace(data);
      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) alert("User not authenticated");

        throw new Error("Error creating profile");
      }
      if ("ok" in response) {
        window.location.href = "/home";
      }
    } catch (error) {
      console.error({ error });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex justify-center">
      <div className="flex flex-col w-1/4 pt-40 gap-y-8">
        <span className="text-4xl font-semibold">New workspace</span>
        <form className="flex flex-col gap-y-6" onSubmit={handleSubmit(onSubmit)}>
          <div className="flex flex-col">
            <input
              {...register("name", { required: "Name is required" })}
              type="text"
              placeholder="Type name"
              className="h-10 w-11/12 rounded-lg border border-gray-300 px-2"
            />
            <span className="text-red-500 h-2">{errors.name ? "Name is required" : ""}</span>
          </div>
          <button
            type="submit"
            className={`bg-green-400 w-11/12 text-white px-8 py-2 rounded-lg mb-4 flex items-center justify-center ${loading ? "cursor-wait" : ""}`}
            disabled={loading}>
            {loading ? (
              <svg
                className="animate-spin h-5 w-5 mr-3"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24">
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"></circle>
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V4a10 10 0 00-10 10h2zm0 0a8 8 0 008 8v-2a10 10 0 01-10-10h2zm0 0a8 8 0 018 8h-2a10 10 0 00-10-10v2z"></path>
              </svg>
            ) : (
              "Create Workspace"
            )}
          </button>
        </form>
      </div>
    </div>
  );
}

Workspace.getLayout = function getLayout(page: React.ReactNode) {
  return page;
};

export default Workspace;
