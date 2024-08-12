import { CandidCanister } from "@bundly/ares-core";

import { WorkspaceIndexActor, workspaceIndex } from "./workspace-index";

export type CandidActors = {
  workspaceIndex: WorkspaceIndexActor;
};

export let candidCanisters: Record<keyof CandidActors, CandidCanister> = {
  workspaceIndex,
};
