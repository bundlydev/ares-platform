import { ActorSubclass } from "@dfinity/agent";

import { CandidCanister } from "@bundly/ares-core";

import { _SERVICE, idlFactory } from "../declarations/backoffice-gateway/backoffice-gateway.did.js";

export type BackofficeGatewayActor = ActorSubclass<_SERVICE>;

export const backofficeGateway: CandidCanister = {
  idlFactory,
  actorConfig: {
    canisterId: process.env.NEXT_PUBLIC_BACKOFFICE_GATEWAY_CANISTER_ID!,
  },
};
