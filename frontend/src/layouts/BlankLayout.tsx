import { FC, ReactNode } from "react";

type BlankLayoutProps = {
  children: ReactNode;
};

const BlankLayout: FC<BlankLayoutProps> = ({ children }) => {
  return <div>{children}</div>;
};

export default BlankLayout;
