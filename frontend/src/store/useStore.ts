import create from "zustand";
import { PersistOptions, persist } from "zustand/middleware";

// Definimos los tipos para el estado y las acciones
interface StoreState {
  userMid: string;
  userIAMid: string;
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
      userMid: "", // Estado inicial de userMid como string
      userIAMid: "", // Estado inicial de userIAMid como string
      setUserMid: (value: string) => set((state: StoreState) => ({ ...state, userMid: value })), // Mantiene el estado existente
      setUserIAMid: (value: string) => set((state: StoreState) => ({ ...state, userIAMid: value })), // Mantiene el estado existente
    }),
    {
      name: "count-storage", // Nombre en el localStorage
      getStorage: () => localStorage, // Configuración para obtener localStorage
    }
  )
);

export default useStore;
