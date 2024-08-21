import { ActorSubclass } from "@dfinity/agent";

import { CandidCanister } from "@bundly/ares-core";

import { _SERVICE, idlFactory } from "../declarations/workspace-iam/workspace-iam.did.js";

export type WorkspaceIamActor = ActorSubclass<_SERVICE>;

export const workspaceIam: CandidCanister = {
  idlFactory,
  actorConfig: {
    canisterId: "",
  },
};
