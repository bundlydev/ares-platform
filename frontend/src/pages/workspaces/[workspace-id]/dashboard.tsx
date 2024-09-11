import { Principal } from "@dfinity/principal";
import { useRouter } from "next/router";
import { useContext, useEffect, useRef, useState } from "react";

import { LogoutButton, useIdentities } from "@bundly/ares-react";

import SelectWorkspace from "@app/components/SelectWorkspace";
import { useAuthGuard } from "@app/hooks/useGuard";
import { useProfile } from "@app/hooks/useProfile";
import { useWorkspaces } from "@app/hooks/useWorkspaces";
import WorkspaceLayout from "@app/layouts/WorkspaceLayout";

export default function WorkspaceDashboardPage(): JSX.Element {
  useAuthGuard({ isPrivate: true });
  return (
    <WorkspaceLayout>
      <div className="flex flex-col w-full p-8">
        <span className="text-7xl font-semibold">Dashboard</span>
      </div>
    </WorkspaceLayout>
  );
}
