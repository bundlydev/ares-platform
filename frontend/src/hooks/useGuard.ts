import { useRouter } from "next/router";
import { useEffect, useState } from "react";

import { useAuth } from "@bundly/ares-react";

import { useProfile } from "./useProfile";
import { useWorkspace } from "./useWorkspace";

export type AuthGuardOptions = {
  isPrivate: boolean;
};

export function useAuthGuard({ isPrivate }: AuthGuardOptions) {
  const router = useRouter();
  const { isAuthenticated } = useAuth();
  const profile = useProfile();
  const workspaces = useWorkspace();
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
        if (router.pathname === "/addworkspace") {
          setLoading(false);
          return;
        }

        if (workspaces && workspaces.length > 0) {
          redirect("/home");
        } else {
          redirect("/workspace");
        }
      } else {
        redirect("/profile");
      }
    } else {
      if (isAuthenticated && router.pathname !== "/addworkspace") {
        redirect("/home");
      }
    }
    setLoading(false);
  }, [isAuthenticated, profile, workspaces, router, isPrivate]);

  return loading;
}
