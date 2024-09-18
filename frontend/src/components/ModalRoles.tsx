import { Principal } from "@dfinity/principal";
import { zodResolver } from "@hookform/resolvers/zod";
import React, { ChangeEvent, FC, useContext, useEffect, useRef, useState } from "react";
import { SubmitHandler, useForm } from "react-hook-form";
import { z } from "zod";

import { useAuth, useCandidActor } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters/index";

import { AuthContext } from "../context/auth-context";
import LoadingSpinner from "./LoadingSpinner";
import useStore from "@app/store/useStore";

interface NameData {
  id: string;
  username: string;
}

interface PoliciesData {
  label: string;
  value: string;
}

type FormValues = {
  name: string;
  description: string;
  policie: string[]; 
};

const formSchema = z.object({
  name: z.string().min(1, "Name is required"), 
  description: z.string().min(1, "Description is required"),
  policie: z.array(z.string()).min(1, "At least one policy is required"), 
});

interface ModalProps {
  showModal: boolean;
  setShowModal: (show: boolean) => void;
  getListFindName: (nameText: string) => void;
  dataNameSearch: NameData[];
	getData: any;
}

const ModalRoles: FC<ModalProps> = ({ showModal, setShowModal, getListFindName, dataNameSearch, getData }) => {
  const { currentIdentity } = useAuth();
	const { userIAMid } = useStore();
  const [inputValue, setInputValue] = useState<string>("");
  const { workspaceId } = useContext(AuthContext);
  const [loading, setLoading] = useState(false);
  const [selectedNames, setSelectedNames] = useState<NameData[]>([]);
  const [selectedPolicies, setSelectedPolicies] = useState<PoliciesData[]>([]);
  const [selectedPolicyValues, setSelectedPolicyValues] = useState<string[]>([]);
  const [isDropdownOpen, setIsDropdownOpen] = useState<boolean>(false);
  const dropdownRef = useRef<HTMLDivElement>(null); 

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(formSchema), 
  });

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setInputValue(value);

    if (value.length >= 3) {
      getListFindName(value);
    } else {
      setSelectedNames([]);
    }
  };

  const workspaceIam = workspaceId
    ? (useCandidActor<CandidActors>("workspaceIam", currentIdentity, {
        canisterId: userIAMid,
      }) as CandidActors["workspaceIam"])
    : null;

  const filteredDataNameSearch = dataNameSearch.filter(
    (name) => !selectedNames.some((selected) => selected.id === name.id)
  );

  const getPolicies = async () => {
    if (!workspaceIam) return;

    const getRolesResult = await workspaceIam.get_policies();
    if ("ok" in getRolesResult) {
      const policiesOptions = getRolesResult.ok.map((policies) => ({
        label: policies.pid,
        value: policies.pid,
      }));
      setSelectedPolicies(policiesOptions);
    } else {
      let error = getRolesResult.err;
      console.error(error);
    }
  };

  useEffect(() => {
    getPolicies();
  }, [workspaceIam]);

  useEffect(() => {
    if (inputValue === "") {
      setSelectedNames([]);
    }
  }, [inputValue]);

  useEffect(() => {
    setValue("policie", selectedPolicyValues); 
  }, [selectedPolicyValues, setValue]);

  const togglePolicySelection = (policyValue: string) => {
    if (selectedPolicyValues.includes(policyValue)) {
      setSelectedPolicyValues(selectedPolicyValues.filter((value) => value !== policyValue));
    } else {
      setSelectedPolicyValues([...selectedPolicyValues, policyValue]);
    }
  };

  const toggleSelectAllPolicies = () => {
    if (selectedPolicyValues.length === selectedPolicies.length) {
      setSelectedPolicyValues([]); 
    } else {
      setSelectedPolicyValues(selectedPolicies.map((policy) => policy.value)); 
    }
  };

  const toggleDropdown = () => {
    setIsDropdownOpen(!isDropdownOpen); 
  };

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsDropdownOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, []);

  const getSelectedPoliciesText = () => {
    if (selectedPolicyValues.length === 0) return "Select Policies";
    if (selectedPolicyValues.length === selectedPolicies.length) return "All Policies Selected";
    return selectedPolicies
      .filter((policy) => selectedPolicyValues.includes(policy.value))
      .map((policy) => policy.label)
      .join(", ");
  };

  if (!showModal) {
    return null;
  }

  const onSubmit: SubmitHandler<FormValues> = async (data) => {
    if (!workspaceIam) return;
    setLoading(true);
    try {
      const response = await workspaceIam.create_role({
        name: data.name,
        description: data.description,
        policies: data.policie,
      });

      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) alert("User not authenticated");

        throw new Error("Error creating profile");
      }
      if ("ok" in response) {
				setShowModal(false)     
				getData() }
    } catch (error) {
      console.error({ error });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 flex justify-center items-center">
      <div className="bg-white p-6 rounded shadow-lg w-1/3">
        <form className="flex flex-col gap-y-6" onSubmit={handleSubmit(onSubmit)}>
          <h2 className="text-xl mb-4">Add Roles</h2>
          <div className="flex flex-col">
            <label htmlFor="name" className="text-gray-700 font-semibold">
              Name
            </label>
            <input
              {...register("name")}
              id="name"
              type="text"
              placeholder="Type Name"
              className="h-10 w-full rounded-lg border border-gray-300 px-2"
            />
            <span className="text-red-500 h-2">{errors.name?.message}</span>
          </div>
          <div className="flex flex-col">
            <label htmlFor="description" className="text-gray-700 font-semibold">
              Description
            </label>
            <input
              {...register("description")}
              id="description"
              type="text"
              placeholder="Type Description"
              className="h-10 w-full rounded-lg border border-gray-300 px-2"
            />
            <span className="text-red-500 h-2">{errors.description?.message}</span>
          </div>
          <div className="flex flex-col" ref={dropdownRef}>
            <label htmlFor="policie" className="text-gray-700 font-semibold">
              Policies
            </label>
            <div
              className="relative bg-white border w-full border-gray-300 mt-2 p-2 rounded-md"
              onClick={toggleDropdown}
              style={{ cursor: "pointer" }}>
              <div className="flex justify-between items-center">
                <span>{getSelectedPoliciesText()}</span>
                <svg
                  className={`transition-transform transform ${isDropdownOpen ? "rotate-180" : "rotate-0"} w-5 h-5`}
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </div>
              {isDropdownOpen && (
                <div className="absolute z-10 left-0 right-0 bg-white border border-gray-300 rounded-md mt-1 max-h-40 overflow-y-auto">
                  <div className="p-2">
                    <div className="flex items-center">
                      <input
                        type="checkbox"
                        checked={selectedPolicyValues.length === selectedPolicies.length}
                        onChange={toggleSelectAllPolicies}
                        className="accent-cyan-950 mr-2"
                      />
                      <span>Select All</span>
                    </div>
                    {selectedPolicies.map((policy) => (
                      <div key={policy.value} className="flex items-center mt-2">
                        <input
                          type="checkbox"
                          checked={selectedPolicyValues.includes(policy.value)}
                          onChange={() => togglePolicySelection(policy.value)}
                          className="accent-cyan-950 mr-2"
                        />
                        <span>{policy.label}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
            <span className="text-red-500 h-2">{errors.policie?.message}</span>
          </div>
          <div className="flex justify-end">
            <button
              className="bg-white text-gray px-4 py-2"
              onClick={() => setShowModal(false)}
              type="button">
              Cancel
            </button>
            <button className="bg-green-400 text-white px-8 py-2 rounded-lg mr-2" type="submit">
              {loading ? <LoadingSpinner /> : "Add"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ModalRoles;
