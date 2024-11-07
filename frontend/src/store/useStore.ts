import create from "zustand";
import { PersistOptions, persist } from "zustand/middleware";

// Definimos los tipos para el estado y las acciones
interface StoreState {
  userMid: string;
  userIAMid: string;
	workspaceRefId: string;
  setWorkspaceRefId: (value: string) => void;
  setUserMid: (value: string) => void;
  setUserIAMid: (value: string) => void;
	
}

// Definimos los tipos para persist
type MyPersist = (
  config: (set: (fn: (state: StoreState) => Partial<StoreState>) => void) => StoreState,
  options: PersistOptions<StoreState>
) => (set: any, get: any, api: any) => StoreState;

const useStore = create<StoreState>(
  (persist as MyPersist)(
    (set) => ({
      userMid: "", 
      userIAMid: "", 
			workspaceRefId: "", 
      setWorkspaceRefId: (value: string) => set((state: StoreState) => ({ ...state, workspaceRefId: value })), 
      setUserMid: (value: string) => set((state: StoreState) => ({ ...state, userMid: value })),
      setUserIAMid: (value: string) => set((state: StoreState) => ({ ...state, userIAMid: value })),
    }),
    {
      name: "count-storage", 
      getStorage: () => localStorage, 
    }
  )
);

export default useStore;
