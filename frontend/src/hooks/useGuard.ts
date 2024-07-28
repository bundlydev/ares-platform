import { useRouter } from 'next/router';
import { useAuth } from '@bundly/ares-react';
import { useProfile } from './useProfile';
import { useWorkspace } from './useWorkspace';

export type AuthGuardOptions = {
  isPrivate: boolean;
};

export function useAuthGuard({ isPrivate }: AuthGuardOptions) {
  const router = useRouter();
  const { isAuthenticated } = useAuth();
  const profile = useProfile();
  const workspaces = useWorkspace();
console.log(workspaces,'workspacesssssss')
  const redirect = (path: string) => {
    if (router.pathname !== path) {
      router.push(path);
    }
  };

  if (isPrivate) {
    if (!isAuthenticated) {
      redirect('/');
      return;
    }
		
    if (profile) {
			if (workspaces!==null && workspaces!==undefined &&workspaces.length >0) {
				redirect('/home');
			}
			else{
				redirect('/workspace');
			}
    } else {
      redirect('/profile');
    }
  } else {
    if (isAuthenticated) {
     
    }
  }
}
