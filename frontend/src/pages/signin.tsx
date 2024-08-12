import { useRouter } from "next/router";
import React, { useContext, useEffect, useState } from "react";
import { SubmitHandler, useForm } from "react-hook-form";

import { useAuth, useCandidActor } from "@bundly/ares-react";
import Header from '../components/header';
import { CandidActors } from "@app/canisters";
import { useAuthGuard } from "@app/hooks/useGuard";

import { AuthContext } from "../context/auth-context";

// Import your AuthContext

type FormValues = {
  name: string;
};

export default function Sigin() {
  const { isAuthenticated, currentIdentity } = useAuth();
	useAuthGuard({ isPrivate: true });
  const router = useRouter();
  const backofficeGateway = useCandidActor<CandidActors>(
    "backofficeGateway",
    currentIdentity
  ) as CandidActors["backofficeGateway"];
  const [image, setImage] = useState<File | null>(null);
  const [submissionSuccess, setSubmissionSuccess] = useState(false); 
  const [loading, setLoading] = useState(false); 
	const { setWorkspaceId } = useContext(AuthContext);
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>();

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setImage(e.target.files[0]);
    }
  };

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      setImage(e.dataTransfer.files[0]);
    }
  };

  const handleDragOver = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
  };

  const onSubmit: SubmitHandler<FormValues> = async (data) => {
    setLoading(true); 
    try {
      const response = await backofficeGateway.createWorkspace(data);
      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) alert("User not authenticated");
        throw new Error("Error creating workspace");
      }
      if ("ok" in response) {
				setWorkspaceId(response.ok.workspaceId.toString())
        setSubmissionSuccess(true); 
      }
    } catch (error) {
      console.error({ error });
    } finally {
      setLoading(false); 
    }
  };
	useEffect(() => {
    if (submissionSuccess) {
      window.location.reload(); 
    }
  }, [submissionSuccess]);


  return (
    <Header/>
  );
}