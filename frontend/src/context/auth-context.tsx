import React, { ReactNode, createContext, useEffect, useState } from "react";
import z from "zod";
import { useCandidActor, useAuth } from "@bundly/ares-react";
import { CandidActors } from "@app/canisters/index";

export type AuthUserProfile = {
  username: string;
  email: string;
  firstName: string;
  lastName: string;
};
export type AuthUserWorkspace = {
  ref: string;
  members: Array[];
};


export type AuthContextType = {
  profile?: AuthUserProfile;
	workspace?: AuthUserProfile;
};

export type AuthContextProviderType = {
  children: ReactNode;
};

const ZUserProfileSchema = z.object({
  email: z.string(),
  username: z.string(),
  firstName: z.string(),
  lastName: z.string(),
});
const ZUserWorksSchema = z.object({
  email: z.string(),
  username: z.string(),
  firstName: z.string(),
  lastName: z.string(),
});

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
    ok: ZUserWorksSchema.optional(),
    err: z.object({}).optional(),
  })
  .refine((data) => (data.ok !== undefined) !== (data.err !== undefined), {
    message: 'Either "ok" or "err" should be present, but not both.',
  });

export const AuthContext = createContext<AuthContextType>({});

export const AuthContextProvider = ({ children }: AuthContextProviderType) => {
  const { isAuthenticated, currentIdentity } = useAuth();
  const backofficeGateway = useCandidActor<CandidActors>(
    "backofficeGateway",
    currentIdentity
  ) as CandidActors["backofficeGateway"];
  const [profile, setProfile] = useState<AuthUserProfile | undefined>();
	const [workspace, setWorkspace] = useState<AuthUserProfile | undefined>();
  useEffect(() => {
    async function loadProfile() {
      if (isAuthenticated) {
        try {
          const response = await backofficeGateway.getProfile();
          const responseParse = ZResponseSchema.safeParse(response);

          if (!responseParse.success) {
            throw new Error(`Invalid response schema: ${responseParse.error}`);
          }
          if (responseParse.data.err) {
            setProfile(undefined);
            return;
          }

          const profile: AuthUserProfile = {
            username: responseParse.data.ok?.username || "",
            email: responseParse.data.ok?.email || "",
            firstName: responseParse.data.ok?.firstName || "",
            lastName: responseParse.data.ok?.lastName || "",
          };
          setProfile(profile);
        } catch (error) {
          console.error("Error loading profile:", error);
          setProfile(undefined);
        }
				try {
					const responseWorks = await backofficeGateway.getMyWorkspaces()
					console.log(responseWorks,'usecontext')
debugger
          const responseWorksParse = ZResponseWorksSchema.safeParse(responseWorks);
          if (!responseWorksParse.success) {
            throw new Error(`Invalid response schema: ${responseWorksParse.error}`);
          }
          if (responseWorksParse.data.err) {
            setWorkspace(undefined);
            return;
          }

          const workspace: AuthUserProfile = {
            username: responseWorksParse.data.ok?.username || "",
            email: responseWorksParse.data.ok?.email || "",
            firstName: responseWorksParse.data.ok?.firstName || "",
            lastName: responseWorksParse.data.ok?.lastName || "",
          };
          setWorkspace(workspace);
        } catch (error) {
          setWorkspace(undefined);
        }
      } else {
        setProfile(undefined);
				setWorkspace(undefined);
      }

    }

    loadProfile();
  }, [isAuthenticated, currentIdentity, backofficeGateway]);

  return (
    <AuthContext.Provider value={{ profile }}>
      {children}
    </AuthContext.Provider>
  );
};
