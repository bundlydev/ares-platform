import { Principal } from "@dfinity/principal";
import React, { ReactNode, createContext, useEffect, useState } from "react";
import z from "zod";

import { useAuth, useCandidActor } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters/index";

export type AuthUserProfile = {
  username: string;
  email: string;
  firstName: string;
  lastName: string;
};

export type AuthUserWorkspace = {
  id: string;
  name: string;
};

const ZProfileSchema = z.object({
  username: z.string(),
  email: z.string().email(),
  firstName: z.string(),
  lastName: z.string(),
});

const ZResponseSchema = z.object({
  ok: ZProfileSchema.optional(),
  err: z.union([z.string(), z.record(z.unknown())]).optional(),
});

const ZWorkspaceSchema = z.object({
  id: z.string(),
  name: z.string(),
});

const ZResponseWorksSchema = z.object({
  ok: z.array(ZWorkspaceSchema).optional(),
  err: z.union([z.string(), z.record(z.unknown())]).optional(),
});

export type AuthContextType = {
  profile?: AuthUserProfile;
  workspaces: AuthUserWorkspace[];
  workspaceId?: string;
  ownerId?: string;
  setProfile: (profile: AuthUserProfile) => void;
  setWorkspaceId: (id: string) => void;
  setOwnerId: (id: string) => void;
};

export const AuthContext = createContext<AuthContextType>({
  profile: undefined,
  workspaces: [],
  workspaceId: undefined,
  ownerId: undefined,
  setProfile: () => {},
  setWorkspaceId: () => {},
  setOwnerId: () => {},
});

export const AuthContextProvider = ({ children }: { children: ReactNode }) => {
  const { isAuthenticated, currentIdentity } = useAuth();
  const accountManager = useCandidActor<CandidActors>(
    "accountManager",
    currentIdentity
  ) as CandidActors["accountManager"];
  const workspaceOrchestrator = useCandidActor<CandidActors>(
    "workspaceOrchestrator",
    currentIdentity
  ) as CandidActors["workspaceOrchestrator"];

  const [isReady, setIsReady] = useState(false);
  const [profile, setProfile] = useState<AuthUserProfile | undefined>();
  const [workspaces, setWorkspaces] = useState<AuthUserWorkspace[]>([]);
  const [workspaceId, setWorkspaceId] = useState<string | undefined>();
  const [ownerId, setOwnerId] = useState<string | undefined>();

  useEffect(() => {
    async function loadProfileAndWorkspaces() {
      if (isAuthenticated) {
        try {
          const [profileResponse, workspacesResponse] = await Promise.all([
            accountManager.get_my_info(),
            workspaceOrchestrator.get_my_workspaces(),
          ]);

          if (profileResponse == null || typeof profileResponse !== "object") {
            throw new Error("Invalid profile response");
          }

          if (workspacesResponse == null || typeof workspacesResponse !== "object") {
            throw new Error("Invalid workspaces response");
          }

          const profileParse = ZResponseSchema.safeParse(profileResponse);
          if (!profileParse.success) {
            throw new Error(`Invalid profile response schema: ${profileParse.error}`);
          }

          if ("ok" in workspacesResponse) {
            const convertedWorkspacesResponse = workspacesResponse.ok
              ? workspacesResponse.ok.map((workspace) => ({
                  ...workspace,
                  id: workspace.wip.toString(),
                  name: workspace.name.toString(),
                }))
              : [];

            const workspacesParse = ZResponseWorksSchema.safeParse({
              ...workspacesResponse,
              ok: convertedWorkspacesResponse,
            });

            if (!workspacesParse.success) {
              throw new Error(`Invalid workspaces response schema: ${workspacesParse.error}`);
            }

            let retrievedWorkspaces = workspacesParse.data.ok || [];

            setProfile(profileParse.data.ok);
            setWorkspaces(retrievedWorkspaces);

            if (retrievedWorkspaces.length > 0) {
              setWorkspaceId(retrievedWorkspaces[0].id);

              const responseOwner = await workspaceOrchestrator.get_workspace_info(
                Principal.fromText(retrievedWorkspaces[0].id)
              );

              if (responseOwner && "ok" in responseOwner) {
                setOwnerId(responseOwner.ok.owner.toString());
              }
            }
          } else {
            throw new Error("Workspaces response does not contain 'ok' property");
          }
        } catch (error) {
          console.error("Error loading profile or workspaces:", error);
        }
      } else {
        setProfile(undefined);
        setWorkspaces([]);
      }

      setIsReady(true);
    }

    loadProfileAndWorkspaces();
  }, [isAuthenticated, currentIdentity]);

  const updateProfile = (newProfile: AuthUserProfile) => {
    setProfile(newProfile);
  };

  return (
    isReady && (
      <AuthContext.Provider
        value={{
          profile,
          workspaces,
          workspaceId,
          setProfile: updateProfile,
          setWorkspaceId,
          setOwnerId,
          ownerId,
        }}>
        {children}
      </AuthContext.Provider>
    )
  );
};
