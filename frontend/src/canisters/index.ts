import { CandidCanister } from "@bundly/ares-core";

import { AccountManagerActor, accountManager } from "./account-manager";
import { WorkspaceIamActor, workspaceIam } from "./workspace-iam";
import { WorkspaceOrchestratorActor, workspaceOrchestrator } from "./workspace-orchestrator";
import { WorkspaceUserActor, workspaceUser } from "./workspace-user-management";

export type CandidActors = {
  accountManager: AccountManagerActor;
  workspaceOrchestrator: WorkspaceOrchestratorActor;
  workspaceIam: WorkspaceIamActor;
	workspaceUser: WorkspaceUserActor
};

export let candidCanisters: Record<keyof CandidActors, CandidCanister> = {
  accountManager,
  workspaceOrchestrator,
  workspaceIam,
	workspaceUser,
};
