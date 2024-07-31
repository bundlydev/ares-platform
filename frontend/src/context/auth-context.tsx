import React, { ReactNode, createContext, useEffect, useState } from "react";
import z from "zod";
import { useAuth, useCandidActor } from "@bundly/ares-react";
import { CandidActors } from "@app/canisters/index";

// Define your types and schemas...

export type AuthUserProfile = {
  username: string;
  email: string;
  firstName: string;
  lastName: string;
};

export type AuthUserWorkspace = {
  id: string; // Convert principal to string for front-end handling
  members: string[];
};

// Define Zod schemas
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
  members: z.array(z.string()),
});

const ZResponseWorksSchema = z.object({
  ok: z.array(ZWorkspaceSchema).optional(),
  err: z.union([z.string(), z.record(z.unknown())]).optional(),
});

export type AuthContextType = {
  profile?: AuthUserProfile;
  workspaces?: AuthUserWorkspace[];
  setProfile: (profile: AuthUserProfile) => void;
	setWorkspaces: (workspaces: AuthUserWorkspace) => void;
};

export const AuthContext = createContext<AuthContextType>({
  profile: undefined,
  workspaces: undefined,
  setProfile: () => {}, // Default function does nothing
	setWorkspaces: () => {}, // Default function does nothing
});

export const AuthContextProvider = ({ children }: { children: ReactNode }) => {
  const { isAuthenticated, currentIdentity } = useAuth();
  const backofficeGateway = useCandidActor<CandidActors>(
    "backofficeGateway",
    currentIdentity
  ) as CandidActors["backofficeGateway"];

  const [profile, setProfile] = useState<AuthUserProfile | undefined>();
  const [workspaces, setWorkspaces] = useState<AuthUserWorkspace[] | undefined>();

  useEffect(() => {
    async function loadProfileAndWorkspaces() {
      if (isAuthenticated) {
        try {
          const [profileResponse, workspacesResponse] = await Promise.all([
            backofficeGateway.getProfile(),
            backofficeGateway.getMyWorkspaces(),
          ]);

          // Ensure responses are objects
          if (profileResponse == null || typeof profileResponse !== 'object') {
            throw new Error("Invalid profile response");
          }

          if (workspacesResponse == null || typeof workspacesResponse !== 'object') {
            throw new Error("Invalid workspaces response");
          }

          // Parse responses with Zod
          const profileParse = ZResponseSchema.safeParse(profileResponse);
          if (!profileParse.success) {
            throw new Error(`Invalid profile response schema: ${profileParse.error}`);
          }

          // Check if workspacesResponse has 'ok' property
          if ('ok' in workspacesResponse) {
            const convertedWorkspacesResponse = workspacesResponse.ok
              ? workspacesResponse.ok.map((workspace: any) => ({
                  ...workspace,
                  id: workspace.id.toString(), // Convert `principal` to string
                  members: workspace.members.map((member: any) => member.toString()), // Convert each `member` to string
                }))
              : [];

            const workspacesParse = ZResponseWorksSchema.safeParse({
              ...workspacesResponse,
              ok: convertedWorkspacesResponse,
            });

            if (!workspacesParse.success) {
              throw new Error(`Invalid workspaces response schema: ${workspacesParse.error}`);
            }

            setProfile(profileParse.data.ok || undefined);
            setWorkspaces(workspacesParse.data.ok || undefined);
          } else {
            throw new Error("Workspaces response does not contain 'ok' property");
          }
        } catch (error) {
          console.error("Error loading profile or workspaces:", error);
          setProfile(undefined);
          setWorkspaces(undefined);
        }
      } else {
        setProfile(undefined);
        setWorkspaces(undefined);
      }
    }

    loadProfileAndWorkspaces();
  }, [isAuthenticated, currentIdentity]);

  const updateProfile = (newProfile: AuthUserProfile) => {
    setProfile(newProfile);
  };
	const updateWorkspaces= (newWorkspaces: AuthUserWorkspace) => {
    setWorkspaces(newWorkspaces);
  };

  return (
    <AuthContext.Provider value={{ profile, workspaces, setProfile: updateProfile,setWorkspaces: updateWorkspaces }}>
      {children}
    </AuthContext.Provider>
  );
};
