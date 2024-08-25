import { useRouter } from "next/router";
import React, { FC, ReactNode, useRef, useState } from "react";

import { LogoutButton, useIdentities } from "@bundly/ares-react";

import SelectWorkspace from "../components/SelectWorkspace";
import { useProfile } from "../hooks/useProfile";

const Header: FC = () => {
  const workspaceRef = useRef<HTMLDivElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const identity = useIdentities();
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const profiles = useProfile();

  const getFirstLetter = (text: string): string => {
    return text.charAt(0).toUpperCase();
  };

  const handleToggle = () => {
    setIsOpen(!isOpen);
  };

  return (
    <header className="flex h-16 bg-cyan-950 items-center justify-between px-2">
      <div ref={workspaceRef} className="flex w-1/4 justify-around">
        {profiles && (
          <div className="flex bg-cyan-600 rounded-full h-9 w-9 items-center justify-center">
            <span className="text-white">{getFirstLetter(profiles?.firstName)}</span>
          </div>
        )}
        <SelectWorkspace />
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
                  {" "}
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
          )}
        </div>
      )}
    </header>
  );
};

const MainMenu = () => {
  const router = useRouter();

  let workspaceId = router.query["workspace-id"] as string;

  const handleNavigation = (path: string) => {
    router.push(path);
  };

  return (
    <div
      style={{ height: "calc(100vh - 64px)" }}
      className="flex flex-col justify-start items-center bg-cyan-950 w-56 gap-10 pt-10">
      <div
        onClick={() => handleNavigation("/home")}
        className="cursor-pointer w-48 h-12 rounded-lg flex justify-center items-center bg-slate-100 text-cyan-950 text-2xl font-semibold">
        IAM
      </div>
      <div
        onClick={() => handleNavigation(`/workspaces/${workspaceId}/iam/apps`)}
        className="cursor-pointer w-48 h-12 rounded-lg flex justify-center items-center bg-slate-100 text-cyan-950 text-2xl font-semibold">
        Apps
      </div>
      <div
        onClick={() => handleNavigation(`/workspaces/${workspaceId}/iam/users`)}
        className="cursor-pointer w-48 h-12 rounded-lg flex justify-center items-center bg-slate-100 text-cyan-950 text-2xl font-semibold">
        Users
      </div>
      <div
        onClick={() => handleNavigation(`/workspaces/${workspaceId}/settings`)}
        className="cursor-pointer w-48 h-12 rounded-lg flex justify-center items-center bg-slate-100 text-cyan-950 text-2xl font-semibold">
        Settings
      </div>
    </div>
  );
};

interface WorkspaceLayoutProps {
  children: ReactNode;
}

const WorkspaceLayout: FC<WorkspaceLayoutProps> = ({ children }) => {
  return (
    <div className="flex flex-col">
      <Header />
      <main className="flex items-start">
        <MainMenu />
        <div
          style={{ height: "calc(100vh - 64px)" }}
          className="container w-full flex flex-col justify-start items-end  bg-slate-100 h-full p-6 rounded-lg">
          {children}
        </div>
      </main>
    </div>
  );
};

export default WorkspaceLayout;
