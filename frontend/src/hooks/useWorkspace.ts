import { useContext } from "react";

import { AuthContext } from "@app/context/auth-context";

export function useWorkspace() {
  const { workspaces } = useContext(AuthContext);
  return workspaces;
}
