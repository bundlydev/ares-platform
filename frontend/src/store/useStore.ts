import create from "zustand";
import { PersistOptions, persist } from "zustand/middleware";

interface StoreState {
	workspaceRefId: string;
  setWorkspaceRefId: (value: string) => void;
	
}

type MyPersist = (
  config: (set: (fn: (state: StoreState) => Partial<StoreState>) => void) => StoreState,
  options: PersistOptions<StoreState>
) => (set: any, get: any, api: any) => StoreState;

const useStore = create<StoreState>(
  (persist as MyPersist)(
    (set) => ({
			workspaceRefId: "", 
      setWorkspaceRefId: (value: string) => set((state: StoreState) => ({ ...state, workspaceRefId: value })), 
    }),
    {
      name: "count-storage", 
      getStorage: () => localStorage, 
    }
  )
);

export default useStore;
