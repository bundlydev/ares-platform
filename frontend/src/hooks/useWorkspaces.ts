import { useContext } from "react";

import { AuthContext } from "@app/context/auth-context";

export function useWorkspaces() {
  const { workspaces } = useContext(AuthContext);
  return workspaces;
}
