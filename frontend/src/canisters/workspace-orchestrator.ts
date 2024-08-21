import { ActorSubclass } from "@dfinity/agent";

import { CandidCanister } from "@bundly/ares-core";

import { _SERVICE, idlFactory } from "../declarations/workspace-orchestrator/workspace-orchestrator.did.js";

export type WorkspaceOrchestratorActor = ActorSubclass<_SERVICE>;

export const workspaceOrchestrator: CandidCanister = {
  idlFactory,
  actorConfig: {
    canisterId: process.env.NEXT_PUBLIC_WORKSPACE_ORCHESTRATOR_CANISTER_ID!,
  },
};
