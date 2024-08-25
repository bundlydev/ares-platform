import { useContext, useEffect, useState } from "react";
import { SubmitHandler, useForm } from "react-hook-form";

import { useAuth, useCandidActor } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters";
import { AuthContext } from "@app/context/auth-context";
import { useAuthGuard } from "@app/hooks/useGuard";
import BlankLayout from "@app/layouts/BlankLayout";

type ProfileInputs = {
  username: string;
  firstName: string;
  lastName: string;
  email: string;
};

export default function NewProfilePage(): JSX.Element {
  useAuthGuard({ isPrivate: true });

  const { setProfile } = useContext(AuthContext);
  const { currentIdentity } = useAuth();

  const [submissionSuccess, setSubmissionSuccess] = useState(false);
  const [loading, setLoading] = useState(false);

  const accountManager = useCandidActor<CandidActors>(
    "accountManager",
    currentIdentity
  ) as CandidActors["accountManager"];

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ProfileInputs>();

  const onSubmit: SubmitHandler<ProfileInputs> = async (data) => {
    setLoading(true);
    try {
      const response = await accountManager.create(data);
      if ("ok" in response) {
        setProfile({
          username: data.username,
          email: data.email,
          firstName: data.firstName,
          lastName: data.lastName,
        });
        setSubmissionSuccess(true);
      }
    } catch (error) {
      console.error("Error creating profile:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (submissionSuccess) {
      window.location.reload();
    }
  }, [submissionSuccess]);

  return (
    <BlankLayout>
      <div className="flex justify-center">
        <div className="flex flex-col w-1/4 pt-40 gap-y-8">
          <span className="text-4xl font-semibold">Create profile</span>
          <form className="flex flex-col gap-y-6" onSubmit={handleSubmit(onSubmit)}>
            <div className="flex flex-col">
              <input
                type="text"
                placeholder="Username"
                className={`h-10 w-11/12 rounded-lg border ${errors.username ? "border-red-500" : "border-gray-300"} px-2`}
                {...register("username", {
                  required: "Username is required",
                  pattern: {
                    value: /^[a-zA-Z0-9_]{5,15}$/,
                    message:
                      "Invalid username format. Use 5-15 characters including letters, numbers, and underscores.",
                  },
                })}
              />
              <span className="text-red-500 h-2">{errors.username ? errors.username.message : ""}</span>
            </div>
            <div className="flex flex-col">
              <input
                type="text"
                placeholder="Firstname"
                className={`h-10 w-11/12 rounded-lg border ${errors.firstName ? "border-red-500" : "border-gray-300"} px-2`}
                {...register("firstName", { required: "First name is required" })}
              />
              <span className="text-red-500 h-2">{errors.firstName ? errors.firstName.message : ""}</span>
            </div>
            <div className="flex flex-col">
              <input
                type="text"
                placeholder="Lastname"
                className={`h-10 w-11/12 rounded-lg border ${errors.lastName ? "border-red-500" : "border-gray-300"} px-2`}
                {...register("lastName", { required: "Last name is required" })}
              />
              <span className="text-red-500 h-2">{errors.lastName ? errors.lastName.message : ""}</span>
            </div>
            <div className="flex flex-col">
              <input
                type="text"
                placeholder="Email"
                className={`h-10 w-11/12 rounded-lg border ${errors.email ? "border-red-500" : "border-gray-300"} px-2`}
                {...register("email", {
                  required: "Email is required",
                  pattern: {
                    value: /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/,
                    message: "Invalid email format. Example: email@example.com",
                  },
                })}
              />
              <span className="text-red-500 h-2">{errors.email ? errors.email.message : ""}</span>
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
                "Create Profile"
              )}
            </button>
          </form>
        </div>
      </div>
    </BlankLayout>
  );
}
