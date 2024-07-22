import { useRouter } from "next/router";
import { useAuth } from "@bundly/ares-react";
import { useProfile } from "./useProfile";

export type AuthGuardOptions = {
  isPrivate: boolean;
};

export function useAuthGuard({ isPrivate }: AuthGuardOptions) {
  const router = useRouter();
  const { isAuthenticated } = useAuth();
  const profile = useProfile();
  const redirect = (path: string) => {
    if (router.pathname !== path) {
      router.push(path);
    }
  };
  if (isPrivate && !isAuthenticated) {
    redirect("/");
    return;
  }
  if ( isAuthenticated ) {
    profile ? redirect("/workspace") : redirect("/profile");
    return;
  }

}
