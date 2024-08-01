import { Identity } from "@dfinity/agent";
import React, { ChangeEvent, FormEvent, useEffect, useState } from "react";

import { LogoutButton, useAuth, useCandidActor, useIdentities } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters";
import Header from "@app/components/header";
import { useAuthGuard } from "@app/hooks/useGuard";

type Profile = {
  username: string;
  email: string;
  firstName: string;
  lastName: string;
};

export default function IcConnectPage() {
  const { isAuthenticated, currentIdentity, changeCurrentIdentity } = useAuth();
  const identities = useIdentities();
  const [profile, setProfile] = useState<Profile | undefined>();
  const [loading, setLoading] = useState(false); // State for loader
  useAuthGuard({ isPrivate: false });
  const backofficeGateway = useCandidActor<CandidActors>(
    "backofficeGateway",
    currentIdentity
  ) as CandidActors["backofficeGateway"];

  useEffect(() => {
    getProfile();
  }, [currentIdentity]);

  function formatPrincipal(principal: string): string {
    const parts = principal.split("-");
    const firstPart = parts.slice(0, 2).join("-");
    const lastPart = parts.slice(-2).join("-");
    return `${firstPart}-...-${lastPart}`;
  }

  function disableIdentityButton(identityButton: Identity): boolean {
    return currentIdentity.getPrincipal().toString() === identityButton.getPrincipal().toString();
  }

  async function getProfile() {
    try {
      const response = await backofficeGateway.getProfile();

      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
      }

      const profile = "ok" in response ? response.ok : undefined;
      setProfile(profile);
    } catch (error) {
      console.error("error response", { error });
    }
  }

  return <Header />;
}

type ProfileFormProps = {
  onSubmit: (username: string, email: string, firstName: string, lastName: string) => Promise<void>;
  loading: boolean; // Loader state
};

function CreateProfileForm({ onSubmit, loading }: ProfileFormProps) {
  const [username, setUsername] = useState("");
  const [email, setEmail] = useState("");

  const handleUsernameChange = (event: ChangeEvent<HTMLInputElement>) => {
    setUsername(event.target.value);
  };

  const handleEmailChange = (event: ChangeEvent<HTMLInputElement>) => {
    setEmail(event.target.value);
  };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    // Get firstName and lastName fields from form
    await onSubmit(username, email, "", "");
    resetForm();
  };

  const resetForm = () => {
    setUsername("");
    setEmail("");
  };

  return (
    <form onSubmit={handleSubmit}>
      <div className="mb-4">
        <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="username">
          Username
        </label>
        <input
          className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
          id="username"
          type="text"
          placeholder="Username"
          value={username}
          onChange={handleUsernameChange}
        />
      </div>
      <div className="mb-6">
        <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="email">
          Email
        </label>
        <input
          className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
          id="email"
          placeholder="Email"
          value={email}
          onChange={handleEmailChange}
        />
      </div>
      <div className="flex items-center justify-between">
        <button
          className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
          type="submit"
          disabled={loading} // Disable button while loading
        >
          {loading ? "Creating Profile..." : "Create Profile"}
        </button>
      </div>
    </form>
  );
}
