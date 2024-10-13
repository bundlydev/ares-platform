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

  const workspaceId = router.query["workspace-id"] as string;

  useEffect(() => {
    const redirect = (path: string) => {
      if (router.pathname !== path) {
        router.push(path);
      }
    };

    if (isPrivate) {
      if (!isAuthenticated) {
        redirect("/auth/signin");
        setLoading(false);
        return;
      }
      if (profile) {
        if (router.pathname === "/profile/new") {
          redirect("/workspaces");
        }

        if (router.pathname === `/workspaces/[workspace-id]/settings`) {
          if (workspaces.length > 0) {
            setLoading(false);
            return;
          } else {
            redirect("/workspaces");
            return;
          }
        }

        if (
          router.pathname !== `/workspaces/[workspace-id]/settings` &&
          router.pathname !== `/workspaces/[workspace-id]/iam/apps` &&
          router.pathname !== `/workspaces/[workspace-id]/iam/roles` &&
          router.pathname !== `/workspaces/new`
        ) {
          if (workspaces.length < 1) {
            redirect("/workspaces");
          }
        }
      } else {
        redirect("/profile/new");
      }
    } else {
      if (
        isAuthenticated &&
        router.pathname !== `/workspaces/[workspace-id]/settings` &&
        router.pathname !== `/workspaces/[workspace-id]/iam/apps` &&
        router.pathname !== `/workspaces/[workspace-id]/iam/roles`
      ) {
        redirect("/home");
      }
    }
    setLoading(false);
  }, [isAuthenticated, profile, workspaces, router, isPrivate, workspaceId]);

  return loading;
}
