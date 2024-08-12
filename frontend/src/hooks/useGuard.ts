import { useRouter } from "next/router";
import { useEffect, useState } from "react";

import { useAuth } from "@bundly/ares-react";

import { useProfile } from "./useProfile";
import { useWorkspaces } from "./useWorkspaces";

export type AuthGuardOptions = {
  isPrivate: boolean;
};

export function useAuthGuard({ isPrivate }: AuthGuardOptions) {
  const router = useRouter();
  const { isAuthenticated } = useAuth();
  const profile = useProfile();
  const workspaces = useWorkspaces();
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const redirect = (path: string) => {
      if (router.pathname !== path) {
        router.push(path);
      }
    };

    if (isPrivate) {
      if (!isAuthenticated) {
        redirect("/signin");
        setLoading(false);
        return;
      }

      if (profile) {
        if (router.pathname === "/settings") {
          if (workspaces.length > 0) {
            setLoading(false);
            return;
          } else {
            redirect("/workspace");
            return;
          }
        }
        if (router.pathname !== "/settings" && router.pathname !== "/addworkspace") {
          if (workspaces.length > 0) {
            redirect("/home");
          } else {
            redirect("/workspace");
          }
        }
      } else {
        redirect("/profile");
      }
    } else {
      if (isAuthenticated && router.pathname !== "/addworkspace" && router.pathname !== "/settings") {
        redirect("/home");
      }
    }
    setLoading(false);
  }, [isAuthenticated, profile, workspaces, router, isPrivate]);

  return loading;
}
