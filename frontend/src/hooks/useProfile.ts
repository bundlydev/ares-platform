import { useContext } from "react";

import { AuthContext } from "@app/context/auth-context";

export function useProfile() {
  const { profile } = useContext(AuthContext);

  return profile;
}