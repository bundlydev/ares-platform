import React, { FC, useState } from "react";

interface ModalProps {
  showModalDelete: boolean;
  setShowModalDelete: (show: boolean) => void;
  deleteItem: string;
  onConfirmDelete: () => void;
}

const ModalDelete: FC<ModalProps> = ({ showModalDelete, setShowModalDelete, deleteItem, onConfirmDelete }) => {
  const [inputValue, setInputValue] = useState<string>("");

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(event.target.value);
  };

  const handleDelete = () => {
    if (inputValue === deleteItem) {
      onConfirmDelete();
      setShowModalDelete(false);
    } else {
      alert("El nombre del workspace no coincide. Inténtalo de nuevo.");
    }
  };

  if (!showModalDelete) {
    return null;
  }

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 flex justify-center items-center">
      <div className="bg-white p-6 rounded-lg shadow-lg w-1/4">
        <h2 className="text-xl mb-4">¿Are you sure you want to delete this workspace?</h2>
        <p className="mb-4">To confirm, type the name of the workspace:</p>
        <span className="font-bold mb-4">"{deleteItem}"</span>
        <input
          type="text"
          value={inputValue}
          onChange={handleInputChange}
          className="w-full p-2 mt-2 border rounded-lg"
          placeholder="Workspace"
        />
        <div className="flex justify-end pt-10">
          <button
            className="bg-white w-1/2 text-gray-700 px-4 py-2 border-gray-400"
            onClick={() => setShowModalDelete(false)}
          >
            Cancelar
          </button>
          <button
            className="bg-red-400 w-1/2 text-white px-8 py-2 rounded-lg ml-2"
            onClick={handleDelete}
          >
            Eliminar
          </button>
        </div>
      </div>
    </div>
  );
};

export default ModalDelete;
