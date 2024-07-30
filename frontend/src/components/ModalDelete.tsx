import React, { ChangeEvent, FC, useState } from "react";

interface ModalProps {
  showModalDelete: boolean;
  setShowModalDelete: (show: boolean) => void;
  deleteItem: string;
}

const ModalDelete: FC<ModalProps> = ({ showModalDelete, setShowModalDelete, deleteItem }) => {
  const [inputValue, setInputValue] = useState<string>("");
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const items = ["Juan Carlos", "María Lupe"]; // Lista de elementos para autocompletar

  const handleAdd = () => {
    setShowModalDelete(false);
  };

  if (!showModalDelete) {
    return null;
  }

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 flex justify-center items-center">
      <div className="bg-white p-6 rounded-lg shadow-lg w-1/4">
        <h2 className="text-xl mb-4">Are you sure you want to delete this user?</h2>
        <span>"{deleteItem}"</span>
        <div className="flex justify-end pt-10">
          <button
            className="bg-white w-1/2 text-gray px-4 py-2 border-gray-400"
            onClick={() => setShowModalDelete(false)}>
            Cancel
          </button>
          <button className="bg-red-400 w-1/2 text-white px-8 py-2 rounded-lg mr-2" onClick={handleAdd}>
            Delete
          </button>
        </div>
      </div>
    </div>
  );
};

export default ModalDelete;
