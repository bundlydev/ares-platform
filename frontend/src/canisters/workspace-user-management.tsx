import { ActorSubclass } from "@dfinity/agent";

import { CandidCanister } from "@bundly/ares-core";

import { _SERVICE, idlFactory } from "../declarations/workspace-user-management/workspace-user-management.did.js";

export type WorkspaceUserActor = ActorSubclass<_SERVICE>;

export const workspaceUser: CandidCanister = {
  idlFactory,
  actorConfig: {
    canisterId: "",
  },
};
