import React, { FC, ReactNode, useRef, useState } from "react";

import { LogoutButton, useAuth, useCandidActor, useIdentities } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters/index";
import { useAuthGuard } from "@app/hooks/useGuard";

import LoadingSpinner from "../components/LoadingSpinner";
import Menu from "../components/Menu";
import Modal from "../components/Modal";
import SelectWorkspace from "../components/SelectWorkspace";
import { AuthContext } from "../context/auth-context";
import { useProfile } from "../hooks/useProfile";
import { useWorkspaces } from "../hooks/useWorkspaces";

interface LayoutProps {
  children: ReactNode;
}

const Layout: FC<LayoutProps> = ({ children }) => {
  const workspaceRef = useRef<HTMLDivElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const workspaces = useWorkspaces();
  const identity = useIdentities();
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const { currentIdentity } = useAuth();
  const profiles = useProfile();
  const getFirstLetter = (text: string): string => {
    return text.charAt(0).toUpperCase();
  };
  const handleToggle = () => {
    setIsOpen(!isOpen);
  };
  return (
    <div className="flex flex-col">
      <div className="flex h-16 bg-cyan-950 items-center justify-between px-2">
        <div ref={workspaceRef} className="flex w-1/4 justify-around">
          {profiles && (
            <div className="flex bg-cyan-600 rounded-full h-9 w-9 items-center justify-center">
              <span className="text-white">{getFirstLetter(profiles?.firstName)}</span>
            </div>
          )}
          {workspaces && <SelectWorkspace />}
        </div>
        {profiles && (
          <div className="relative inline-block text-left" ref={menuRef}>
            <div
              className="flex bg-cyan-600 rounded-full h-9 w-9 items-center justify-center cursor-pointer"
              onClick={handleToggle}>
              <span className="text-white">{getFirstLetter(profiles?.firstName)}</span>
            </div>
            {isOpen && identity.length > 0 && (
              <div className="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5">
                <div role="menu" aria-orientation="vertical" aria-labelledby="options-menu">
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
                      padding: "10px 15px",
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
      </div>
      <div className="flex items-start">
        <Menu />
        <div
          style={{ height: "calc(100vh - 64px)" }}
          className="container w-full flex flex-col justify-start items-end  bg-slate-100 h-full p-6 rounded-lg">
          {children}
        </div>
      </div>
    </div>
  );
};

export default Layout;
