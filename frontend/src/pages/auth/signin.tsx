import { InternetIdentityButton } from "@bundly/ares-react";

import BlankLayout from "@app/layouts/BlankLayout";

import iconICP from "../images/iconICP.png";

export default function SiginPage() {
  return (
    <BlankLayout>
      <div className="mx-auto flex flex-col max-w-7xl items-center gap-10 p-60 lg:px-8" aria-label="Global">
        <div className="text-[36px] font-semibold">ARES PLATFORM</div>
        <div className="lg:flex lg:gap-x-12"></div>
        <div className="lg:flex lg:flex-1 lg:justify-end">
          <InternetIdentityButton
            style={{
              display: "flex",
              alignItems: "center",
              background: "#083344",
              padding: "0 ",
              borderRadius: "8px",
              width: "350px",
              justifyContent: "center",
            }}>
            <img src={iconICP.src} alt="Icon" className="w-20" />
            <span className="text-white text-[14px] font-medium ml-2"> INTERNET IDENTITY</span>
          </InternetIdentityButton>
        </div>
      </div>
    </BlankLayout>
  );
}
