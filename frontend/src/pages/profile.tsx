import React, { useState } from "react";
import { useForm, SubmitHandler } from "react-hook-form";
import { LogoutButton, useAuth, useCandidActor, useIdentities } from "@bundly/ares-react";
import { CandidActors } from "@app/canisters";
import Modal from "../components/Modal";
import SelectWorkspace from "../components/SelectWorkspace";

type ProfileInputs = {
  username: string;
  firstName: string;
  lastName: string;
  email: string;
};

export default function Profile() {
  const { isAuthenticated, currentIdentity, changeCurrentIdentity } = useAuth();
  const { register, handleSubmit, formState: { errors } } = useForm<ProfileInputs>();
  const [image, setImage] = useState<File | null>(null);
  const backofficeGateway = useCandidActor<CandidActors>(
    "backofficeGateway",
    currentIdentity
  ) as CandidActors["backofficeGateway"];

  const onSubmit: SubmitHandler<ProfileInputs> = async (data) => {
		debugger
    try {
      const response = await backofficeGateway.createProfile(data);
			debugger
			console.log(response,'responseexitoso')
      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) alert("User not authenticated");
        if ("profileAlreadyExists" in response.err) alert("Profile already exists");

        throw new Error("Error creating profile");
      }
    } catch (error) {
      console.error({ error });
    }
  };

  return (
    <div className="flex justify-center">
      <div className="flex flex-col w-1/4 pt-40 gap-y-8">
        <span className="text-4xl font-semibold">Create profile</span>
        <form className="flex flex-col gap-y-6" onSubmit={handleSubmit(onSubmit)}>
          <div className="flex flex-col">
            <input
              type="text"
              placeholder="Type username"
              className={`h-10 w-11/12 rounded-lg border ${errors.username ? 'border-red-500' : 'border-gray-300'} px-2`}
              {...register("username", { required: true })}
            />
            <span className="text-red-500 h-2">
              {errors.username ? 'Username is required' : ''}
            </span>
          </div>
          <div className="flex flex-col">
            <input
              type="text"
              placeholder="Type firstname"
              className={`h-10 w-11/12 rounded-lg border ${errors.firstName ? 'border-red-500' : 'border-gray-300'} px-2`}
              {...register("firstName", { required: true })}
            />
            <span className="text-red-500 h-2">
              {errors.firstName ? 'First name is required' : ''}
            </span>
          </div>
          <div className="flex flex-col">
            <input
              type="text"
              placeholder="Type lastname"
              className={`h-10 w-11/12 rounded-lg border ${errors.lastName ? 'border-red-500' : 'border-gray-300'} px-2`}
              {...register("lastName", { required: true })}
            />
            <span className="text-red-500 h-2">
              {errors.lastName ? 'Last name is required' : ''}
            </span>
          </div>
          <div className="flex flex-col">
            <input
              type="text"
              placeholder="Type email"
              className={`h-10 w-11/12 rounded-lg border ${errors.email ? 'border-red-500' : 'border-gray-300'} px-2`}
              {...register("email", { required: true })}
            />
            <span className="text-red-500 h-2">
              {errors.email ? 'Email is required' : ''}
            </span>
          </div>
          <button
            type="submit"
            className="bg-green-400 w-11/12 text-white px-8 py-2 rounded-lg mb-4"
          >
            Create Profile
          </button>
        </form>
      </div>
    </div>
  );
}
