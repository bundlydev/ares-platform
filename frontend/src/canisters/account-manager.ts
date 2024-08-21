import { ActorSubclass } from "@dfinity/agent";

import { CandidCanister } from "@bundly/ares-core";

import { _SERVICE, idlFactory } from "../declarations/account-manager/account-manager.did.js";

export type AccountManagerActor = ActorSubclass<_SERVICE>;

export const accountManager: CandidCanister = {
  idlFactory,
  actorConfig: {
    canisterId: process.env.NEXT_PUBLIC_ACCOUNT_MANAGER_CANISTER_ID!,
  },
};
