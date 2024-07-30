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

export default function Workspace() {
  const { isAuthenticated, currentIdentity, changeCurrentIdentity } = useAuth();
  useAuthGuard({ isPrivate: true });
  const backofficeGateway = useCandidActor<CandidActors>(
    "backofficeGateway",
    currentIdentity
  ) as CandidActors["backofficeGateway"];
  const [image, setImage] = useState<File | null>(null);
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
    try {
      const response = await backofficeGateway.createWorkspace(data);
      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) alert("User not authenticated");

        throw new Error("Error creating profile");
      }
      if ("ok" in response) {
        router.push("/home");
      }
    } catch (error) {
      console.error({ error });
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
          <button type="submit" className="bg-green-400 w-11/12 text-white px-8 py-2 rounded-lg mb-4">
            Create Workspace
          </button>
        </form>
      </div>
    </div>
  );
}
