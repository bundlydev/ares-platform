import { Principal } from "@dfinity/principal";
import { useRouter } from "next/router";
import { FC, useContext, useEffect, useRef, useState } from "react";

import { LogoutButton, useIdentities } from "@bundly/ares-react";

import SelectWorkspace from "@app/components/SelectWorkspace";
import { AuthContext } from "@app/context/auth-context";
import { useAuthGuard } from "@app/hooks/useGuard";
import { useProfile } from "@app/hooks/useProfile";
import { useWorkspaces } from "@app/hooks/useWorkspaces";
import BlankLayout from "@app/layouts/BlankLayout";

const Header: FC = () => {
  const workspaceRef = useRef<HTMLDivElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const router = useRouter();
  const identity = useIdentities();
  const profiles = useProfile();

  const getFirstLetter = (text: string): string => {
    return text.charAt(0).toUpperCase();
  };

  const handleToggle = () => {
    setIsOpen(!isOpen);
  };

  const handleLogout = () => {
    router.push("/auth/signin");
  };

  return (
    <header className="flex h-16 bg-cyan-950 items-center justify-between px-8">
      <div ref={workspaceRef} className="flex w-1/4 justify-between">
        {profiles && (
          <div
            className="flex bg-cyan-600 rounded-full h-9 w-9 items-center justify-center cursor-pointer"
            onClick={() => router.push("/workspaces")}>
            <span className="text-white">{getFirstLetter(profiles?.firstName)}</span>
          </div>
        )}
      </div>
      {profiles && (
        <div className="relative inline-block text-left" ref={menuRef}>
          <div
            className="flex bg-cyan-600 rounded-full h-9 w-9 items-center justify-center cursor-pointer"
            onClick={handleToggle}>
            <span className="text-white">{getFirstLetter(profiles?.firstName)}</span>
          </div>
          {isOpen && identity.length > 0 && (
            <div className="origin-top-right absolute right-0 mt-2 w-72 py-3 px-3 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5">
              <div role="menu" aria-orientation="vertical" aria-labelledby="options-menu">
                <div className="flex gap-3 items-center border-b border-gray-300 pb-3">
                  <div
                    className="flex bg-cyan-600 rounded-full h-9 w-9 items-center justify-center cursor-pointer"
                    onClick={handleToggle}>
                    <span className="text-white">{getFirstLetter(profiles?.firstName)}</span>
                  </div>
                  <div className="flex flex-col">
                    <span className="text-base text-black font-semibold">{profiles.username}</span>
                    <span className="text-xs font-normal text-gray-500">{profiles.email}</span>
                  </div>
                </div>
                {/* Contenedor de Logout que llama a handleLogout antes de LogoutButton */}
                <div
                  onClick={handleLogout}
                  style={{ display: "flex", cursor: "pointer", alignItems: "center" }}>
                  <LogoutButton
                    identity={identity[0].identity}
                    style={{
                      display: "flex",
                      width: "100%",
                      justifyContent: "flex-start",
                      color: "red",
                      fontSize: "18px",
                      alignItems: "center",
                      fontWeight: 500,
                      padding: "10px 0 0 0",
                      gap: "15px",
                    }}>
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      className="feather feather-log-out"
                      style={{ width: "24px", height: "24px" }}>
                      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                      <polyline points="16 17 21 12 16 7"></polyline>
                      <line x1="21" y1="12" x2="9" y2="12"></line>
                    </svg>
                    <span>Logout</span>
                  </LogoutButton>
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </header>
  );
};
export default function DashboardPage(): JSX.Element {
  const { setWorkspaceId } = useContext(AuthContext);
  const router = useRouter();
  useAuthGuard({ isPrivate: true });
  const workspaces = useWorkspaces();
  return (
    <BlankLayout>
      <Header />
      <div className="flex flex-col w-full p-8">
        <div className="flex justify-between">
          <span className="text-3xl font-semibold">Home</span>
          <button
            className="bg-green-400 text-white px-1 py-2 rounded-xl mb-4 w-36 cursor-pointer"
            onClick={() => router.push("/workspaces/new")}>
            New workspace
          </button>
        </div>
        <div className="flex flex-wrap gap-7 py-5">
          {workspaces.map((item, index) => (
            <div
              key={index}
              className="w-1/6 h-32 bg-white border border-gray-300 shadow-lg shadow-slate-400 rounded-xl p-4 cursor-pointer"
              onClick={() => {
                router.push(`/workspaces/${item.id}/dashboard`);
                setWorkspaceId(item.id);
              }}>
              <span className="text-xl font-semibold">{item.name}</span>
            </div>
          ))}
        </div>
      </div>
    </BlankLayout>
  );
}
