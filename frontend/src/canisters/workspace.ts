import { ActorSubclass } from "@dfinity/agent";

import { CandidCanister } from "@bundly/ares-core";

import { _SERVICE, idlFactory } from "../declarations/workspace/workspace.did.js";

export type WorkspaceActor = ActorSubclass<_SERVICE>;

export const workspace: CandidCanister = {
  idlFactory,
  actorConfig: {
    canisterId: '',
  },
};
