"use client";

import type { AppProps } from "next/app";
import "tailwindcss/tailwind.css";

import { Client, InternetIdentity } from "@bundly/ares-core";
import { IcpConnectContextProvider } from "@bundly/ares-react";
import { AuthContextProvider } from "@app/context/auth-context";

import { candidCanisters } from "@app/canisters/index";

export default function MyApp({ Component, pageProps }: AppProps) {
  const client = Client.create({
    agentConfig: {
      host: process.env.NEXT_PUBLIC_IC_HOST_URL!,
			verifyQuerySignatures: false,
    },
    candidCanisters,
    providers: [
      new InternetIdentity({
        providerUrl: process.env.NEXT_PUBLIC_INTERNET_IDENTITY_URL!,
      }),
    ],
  });

  return (
    <IcpConnectContextProvider client={client}>
			 <AuthContextProvider>
      <Component {...pageProps} />
			</AuthContextProvider>
    </IcpConnectContextProvider>
  );
}
