import { CandidCanister } from "@bundly/ares-core";

import { BackofficeGatewayActor, backofficeGateway } from "./backoffice-gateway";
import { WorkspaceActor, workspace } from "./workspace";
export type CandidActors = {
  backofficeGateway: BackofficeGatewayActor;
	workspace: WorkspaceActor;
};

export let candidCanisters: Record<keyof CandidActors, CandidCanister> = {
  backofficeGateway,
	workspace
};
