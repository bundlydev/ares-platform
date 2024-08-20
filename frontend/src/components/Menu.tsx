import { useRouter } from 'next/router';

const Menu = () => {
	const router = useRouter();

  const handleNavigation = (path:string) => {
    router.push(path);
  };

  return (
    <div
      style={{ height: "calc(100vh - 64px)" }}
      className="flex flex-col justify-start items-center bg-cyan-950 w-56 gap-10 pt-10"
    >
      <div
        onClick={() => handleNavigation('/home')}
        className="cursor-pointer w-48 h-12 rounded-lg flex justify-center items-center bg-slate-100 text-cyan-950 text-2xl font-semibold"
      >
        IAM
      </div>
      <div
        onClick={() => handleNavigation('/settings')}
        className="cursor-pointer w-48 h-12 rounded-lg flex justify-center items-center bg-slate-100 text-cyan-950 text-2xl font-semibold"
      >
        Settings
      </div>
			<div
        onClick={() => handleNavigation('/apps')}
        className="cursor-pointer w-48 h-12 rounded-lg flex justify-center items-center bg-slate-100 text-cyan-950 text-2xl font-semibold"
      >
        Apps
      </div>
    </div>
  );
};

export default Menu;