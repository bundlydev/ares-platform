import { ActorSubclass } from "@dfinity/agent";

import { CandidCanister } from "@bundly/ares-core";

import { _SERVICE, idlFactory } from "../declarations/workspace-index/workspace-index.did.js";

export type WorkspaceIndexActor = ActorSubclass<_SERVICE>;

export const workspaceIndex: CandidCanister = {
  idlFactory,
  actorConfig: {
    canisterId: process.env.NEXT_PUBLIC_WORKSPACE_INDEX_CANISTER_ID!,
  },
};
