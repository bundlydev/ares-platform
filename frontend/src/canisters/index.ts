import { CandidCanister } from "@bundly/ares-core";

import { BackofficeGatewayActor, backofficeGateway } from "./backoffice-gateway";

export type CandidActors = {
  backofficeGateway: BackofficeGatewayActor;
};

export let candidCanisters: Record<keyof CandidActors, CandidCanister> = {
  backofficeGateway,
};
