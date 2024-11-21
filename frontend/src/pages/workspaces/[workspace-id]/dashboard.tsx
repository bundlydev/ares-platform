import { useAuthGuard } from "@app/hooks/useGuard";
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
