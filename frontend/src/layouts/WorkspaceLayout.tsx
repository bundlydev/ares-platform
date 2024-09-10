import { useRouter } from "next/router";
import React, { FC, ReactNode, useEffect, useRef, useState } from "react";

import { LogoutButton, useIdentities } from "@bundly/ares-react";

import SelectWorkspace from "../components/SelectWorkspace";
import { useProfile } from "../hooks/useProfile";

const Header: FC = () => {
  const router = useRouter();
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

  const handleLogout = () => {
    router.push("/signin");
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

const MainMenu = () => {
  const router = useRouter();
  const [isIamMenuOpen, setIsIamMenuOpen] = useState(false);
	const [isManagementMenuOpen, setIsManagementMenuOpen] = useState(false);
  const workspaceId = router.query["workspace-id"] as string;

  const handleNavigation = (path: string) => {
    router.push(path);
  };

  const toggleIamMenu = () => {
    setIsIamMenuOpen(!isIamMenuOpen);
  };
	const toggleManagementMenu = () => {
    setIsManagementMenuOpen(!isManagementMenuOpen);
  };

  useEffect(() => {
    if (router.pathname.includes("/iam/")) {
      setIsIamMenuOpen(true);
    } else {
      setIsIamMenuOpen(false);
    }
  }, [router.pathname]);

  const handleSubmenuNavigation = (path: string) => {
    handleNavigation(path);
    setIsIamMenuOpen(true);
  };
	const handleSubmenuNavigationManage = (path: string) => {
    handleNavigation(path);
    setIsManagementMenuOpen(true);
  };

  return (
    <div
      style={{ height: "calc(100vh - 64px)" }}
      className="flex flex-col justify-between items-center bg-cyan-950 w-56 py-3 text-white">
      <div className=" w-full">
        <div
          onClick={toggleIamMenu}
          className="cursor-pointer w-full h-12 flex justify-between items-center text-lg font-semibold relative px-2 text-white">
          <span>IAM</span>
          <svg
            className={`transition-transform transform ${isIamMenuOpen ? "rotate-180" : "rotate-90"} w-5 h-5`}
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
          </svg>
        </div>
				
        {isIamMenuOpen && (
          <div className="flex flex-col w-full">
            <div
              onClick={() => handleSubmenuNavigation(`/workspaces/${workspaceId}/iam/users`)}
              className="cursor-pointer w-full h-12 px-4 flex justify-start items-center text-sm font-semibold text-white"
              style={{
                borderLeft: router.pathname.includes("users") ? "4px solid #06b6d4" : "4px solid #083344",
                background: router.pathname.includes("users") ? "rgba(15, 75, 100, 0.7)" : "#083344",
              }}>
              Users
            </div>
            <div
              onClick={() => handleSubmenuNavigation(`/workspaces/${workspaceId}/iam/apps`)}
              className="cursor-pointer w-full px-4 h-12 flex justify-start items-center text-sm font-semibold text-white"
              style={{
                borderLeft: router.pathname.includes("apps") ? "4px solid #06b6d4" : "4px solid #083344",
                background: router.pathname.includes("apps") ? "rgba(15, 75, 100, 0.7)" : "#083344",
              }}>
              Apps
            </div>
            <div
              onClick={() => handleSubmenuNavigation(`/workspaces/${workspaceId}/iam/roles`)}
              className="cursor-pointer w-full px-4 h-12 flex justify-start items-center text-sm font-semibold text-white"
              style={{
                borderLeft: router.pathname.includes("roles") ? "4px solid #06b6d4" : "4px solid #083344",
                background: router.pathname.includes("roles") ? "rgba(15, 75, 100, 0.7)" : "#083344",
              }}>
              Roles
            </div>
          </div>
        )}
				<div
          onClick={toggleManagementMenu}
          className="cursor-pointer w-full h-12 flex justify-between items-center text-lg font-semibold relative px-2 text-white">
          <span>User management</span>
          <svg
            className={`transition-transform transform ${isManagementMenuOpen ? "rotate-135" : "rotate-45"} w-5 h-5`}
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
          </svg>
        </div>
				{isManagementMenuOpen && (
          <div className="flex flex-col w-full">
            <div
              onClick={() => handleSubmenuNavigationManage(`/management/${workspaceId}/users`)}
              className="cursor-pointer w-full h-12 px-4 flex justify-start items-center text-sm font-semibold text-white"
              style={{
                borderLeft: router.pathname.includes("management") && router.pathname.includes("users") ? "4px solid #06b6d4" : "4px solid #083344",
                background: router.pathname.includes("management") && router.pathname.includes("users") ? "rgba(15, 75, 100, 0.7)" : "#083344",
              }}>
              Users
            </div>
            <div
              onClick={() => handleSubmenuNavigationManage(`/management/${workspaceId}/roles`)}
              className="cursor-pointer w-full px-4 h-12 flex justify-start items-center text-sm font-semibold text-white"
              style={{
                borderLeft: router.pathname.includes("management") && router.pathname.includes("roles") ? "4px solid #06b6d4" : "4px solid #083344",
                background: router.pathname.includes("management") && router.pathname.includes("roles")  ? "rgba(15, 75, 100, 0.7)" : "#083344",
              }}>
              Roles
            </div>
            <div
              onClick={() => handleSubmenuNavigationManage(`/management/${workspaceId}/permissions`)}
              className="cursor-pointer w-full px-4 h-12 flex justify-start items-center text-sm font-semibold text-white"
              style={{
                borderLeft: router.pathname.includes("permissions") ? "4px solid #06b6d4" : "4px solid #083344",
                background: router.pathname.includes("permissions") ? "rgba(15, 75, 100, 0.7)" : "#083344",
              }}>
              Permissions
            </div>
          </div>
        )}
        <div className="flex-grow"></div>
      </div>
      <div
        onClick={() => handleSubmenuNavigation(`/workspaces/${workspaceId}/settings`)}
        className="cursor-pointer w-full h-12 flex justify-start px-2 gap-4 items-center text-lg font-semibold text-white"
        style={{
          borderLeft: router.pathname.includes("settings") ? "4px solid #0891b2" : "4px solid #083344",
          background: router.pathname.includes("settings") ? "rgba(15, 75, 100, 0.7)" : "#083344",
        }}>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          strokeWidth={1.5}
          stroke="currentColor"
          className="size-6"
          style={{ width: "25px", height: "25px" }}>
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.325.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 0 1 1.37.49l1.296 2.247a1.125 1.125 0 0 1-.26 1.431l-1.003.827c-.293.241-.438.613-.43.992a7.723 7.723 0 0 1 0 .255c-.008.378.137.75.43.991l1.004.827c.424.35.534.955.26 1.43l-1.298 2.247a1.125 1.125 0 0 1-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.47 6.47 0 0 1-.22.128c-.331.183-.581.495-.644.869l-.213 1.281c-.09.543-.56.94-1.11.94h-2.594c-.55 0-1.019-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 0 1-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 0 1-1.369-.49l-1.297-2.247a1.125 1.125 0 0 1 .26-1.431l1.004-.827c.292-.24.437-.613.43-.991a6.932 6.932 0 0 1 0-.255c.007-.38-.138-.751-.43-.992l-1.004-.827a1.125 1.125 0 0 1-.26-1.43l1.297-2.247a1.125 1.125 0 0 1 1.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.086.22-.128.332-.183.582-.495.644-.869l.214-1.28Z"
          />
          <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
        </svg>

        <span>Settings</span>
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
          className="container w-full flex flex-col justify-start items-end bg-slate-100 h-full p-6 rounded-lg">
          {children}
        </div>
      </main>
    </div>
  );
};

export default WorkspaceLayout;
