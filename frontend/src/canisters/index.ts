import { CandidCanister } from "@bundly/ares-core";

import { AccountManagerActor, accountManager } from "./account-manager";
import { WorkspaceOrchestratorActor, workspaceOrchestrator } from "./workspace-orchestrator";
import { WorkspaceActor, workspace } from "./workspace";

export type CandidActors = {
  accountManager: AccountManagerActor;
  workspaceOrchestrator: WorkspaceOrchestratorActor;
	workspace: WorkspaceActor;
};

export let candidCanisters: Record<keyof CandidActors, CandidCanister> = {
  accountManager,
  workspaceOrchestrator,
	workspace
};
