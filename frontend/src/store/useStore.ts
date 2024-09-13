import create from 'zustand';
import { persist } from 'zustand/middleware';

const useStore = create(
  persist(
    (set: (arg0: (state: any) => { userMid: any; }) => any) => ({
      userMid: "",
      setUserMid: (value: number) => set((state) => ({ userMid: value })),
			userIAMid: "",
      setUserIAMid: (value: number) => set((state) => ({ userIAMid: value })),
    }),
    {
      name: 'count-storage', 
      getStorage: () => localStorage,
    }
  )
);

export default useStore;
