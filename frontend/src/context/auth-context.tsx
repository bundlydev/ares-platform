import React, { ReactNode, createContext, useEffect, useState } from "react";
import z from "zod";
import { useCandidActor, useAuth } from "@bundly/ares-react";
import { CandidActors } from "@app/canisters/index";

// Define your types
export type AuthUserProfile = {
  username: string;
  email: string;
  firstName: string;
  lastName: string;
};

export type AuthUserWorkspace = {
  ref: string;
  members: string[];
};

// Define Zod schemas
const ZUserProfileSchema = z.object({
  email: z.string(),
  username: z.string(),
  firstName: z.string(),
  lastName: z.string(),
});

const ZUserWorksSchema = z.object({
  ref: z.string(),  // Expect `ref` as a string
  members: z.array(z.string()),  // Expect `members` as an array of strings
});

// Define response schemas
const ZResponseSchema = z
  .object({
    ok: ZUserProfileSchema.optional(),
    err: z.object({}).optional(),
  })
  .refine((data) => (data.ok !== undefined) !== (data.err !== undefined), {
    message: 'Either "ok" or "err" should be present, but not both.',
  });

const ZResponseWorksSchema = z
  .object({
    ok: z.array(ZUserWorksSchema).optional(),
    err: z.object({}).optional(),
  })
  .refine((data) => (data.ok !== undefined) !== (data.err !== undefined), {
    message: 'Either "ok" or "err" should be present, but not both.',
  });

// Create context
export const AuthContext = createContext<AuthContextType>({});

export const AuthContextProvider = ({ children }: AuthContextProviderType) => {
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
            backofficeGateway.getMyWorkspaces()
          ]);

          // Convert ref and members to strings before parsing with Zod
          const convertedWorkspacesResponse = workspacesResponse.ok.map((workspace: any) => ({
            ...workspace,
            ref:workspace.ref.toString(),  // Convert `ref` to a JSON string
            members: workspace.members.map((member: any) => JSON.stringify(member))  // Convert each `member` to a JSON string
          }));

          // Parse responses with Zod
          const profileParse = ZResponseSchema.safeParse(profileResponse);
          const workspacesParse = ZResponseWorksSchema.safeParse({
            ...workspacesResponse,
            ok: convertedWorkspacesResponse
          });

          if (!profileParse.success) {
            throw new Error(`Invalid profile response schema: ${profileParse.error}`);
          }
          if (!workspacesParse.success) {
            throw new Error(`Invalid workspaces response schema: ${workspacesParse.error}`);
          }

          if (profileParse.data.err) {
            setProfile(undefined);
          } else {
            setProfile({
              username: profileParse.data.ok?.username || "",
              email: profileParse.data.ok?.email || "",
              firstName: profileParse.data.ok?.firstName || "",
              lastName: profileParse.data.ok?.lastName || "",
            });
          }
          if (workspacesParse.data.err) {
            setWorkspaces(undefined);
          } else {
            setWorkspaces(workspacesParse.data.ok );
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
  }, [isAuthenticated, currentIdentity, backofficeGateway]);
  return (
    <AuthContext.Provider value={{ profile, workspaces }}>
      {children}
    </AuthContext.Provider>
  );
};
