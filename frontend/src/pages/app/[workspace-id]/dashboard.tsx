import { Principal } from "@dfinity/principal";
import { useRouter } from "next/router";
import { useContext, useEffect, useRef, useState } from "react";

import { useAuthGuard } from "@app/hooks/useGuard";
import WorkspaceLayout from "@app/layouts/WorkspaceLayout";

export default function DashboardPage(): JSX.Element {
  useAuthGuard({ isPrivate: true });

  return (
    <WorkspaceLayout>
      <div className="flex flex-col w-full ">
        <span>Welcome</span>
      </div>
    </WorkspaceLayout>
  );
}
