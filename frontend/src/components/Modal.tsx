import React, { ChangeEvent, FC, useEffect, useState } from "react";

import LoadingSpinner from "./LoadingSpinner";

interface NameData {
  id: string;
  username: string;
}
interface ModalProps {
  showModal: boolean;
  setShowModal: (show: boolean) => void;
  addMemberWorkspace: (userId: string) => void;
  getListFindName: (nameText: string) => void;
  dataNameSearch: NameData[];
  loading: boolean;
}

const Modal: FC<ModalProps> = ({
  showModal,
  setShowModal,
  addMemberWorkspace,
  getListFindName,
  dataNameSearch,
  loading,
}) => {
  const [inputValue, setInputValue] = useState<string>("");
  const [inputValueId, setInputValueId] = useState<string>("");
  const [selectedNames, setSelectedNames] = useState<NameData[]>([]);

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setInputValue(value);

    if (value.length >= 3) {
      getListFindName(value);
    } else {
      setSelectedNames([]);
    }
  };

  const handleSelect = (id: string, username: string) => {
    setInputValue(username);
    setInputValueId(id);
    setSelectedNames((prevSelectedNames) => [...prevSelectedNames, { id, username }]);
  };

  const handleAdd = () => {
    addMemberWorkspace(inputValueId);
    setInputValue("");
    setInputValueId("");
  };

  const filteredDataNameSearch = dataNameSearch.filter(
    (name) => !selectedNames.some((selected) => selected.id === name.id)
  );

  useEffect(() => {
    if (inputValue === "") {
      setSelectedNames([]);
    }
  }, [inputValue]);

  if (!showModal) {
    return null;
  }
  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 flex justify-center items-center">
      <div className="bg-white p-6 rounded shadow-lg w-1/3">
        <h2 className="text-xl mb-4">Add User</h2>
        <input
          type="text"
          className="w-full p-2 border border-gray-300 rounded mb-2"
          placeholder="Type to search..."
          value={inputValue}
          onChange={handleChange}
          disabled={loading}
        />
        {filteredDataNameSearch.length > 0 && (
          <ul className="border border-gray-300 rounded mb-2">
            {filteredDataNameSearch.map((suggestion, index) => (
              <li
                key={index}
                className="p-2 cursor-pointer hover:bg-gray-200"
                onClick={() => handleSelect(suggestion.id, suggestion.username)}>
                {suggestion.username}
              </li>
            ))}
          </ul>
        )}
        <div className="flex justify-end">
          <button className="bg-white text-gray px-4 py-2 " onClick={() => setShowModal(false)}>
            Cancel
          </button>
          <button
            className="bg-green-400 text-white px-8 py-2 rounded-lg mr-2"
            onClick={handleAdd}
            disabled={loading}>
            {loading ? <LoadingSpinner /> : "Add"}
          </button>
        </div>
      </div>
    </div>
  );
};

export default Modal;
