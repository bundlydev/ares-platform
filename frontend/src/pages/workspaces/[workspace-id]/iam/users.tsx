import { useRouter } from "next/router";

import { useAuth, useCandidActor } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters";
import WorkspaceLayout from "@app/layouts/WorkspaceLayout";

export default function WorkspaceUsersPage(): JSX.Element {
  const router = useRouter();
  const { currentIdentity } = useAuth();

  let workspaceId = router.query["workspace-id"] as string;

  const workspaceIam = useCandidActor<CandidActors>("workspaceIam", currentIdentity, {
    canisterId: workspaceId,
  }) as CandidActors["workspaceIam"];

  return (
    <WorkspaceLayout>
      <div>Grant access to user to the workspace: {workspaceId}</div>
    </WorkspaceLayout>
  );
}
