import React, { ChangeEvent, FC, useState } from "react";

interface ModalProps {
  showModal: boolean;
  setShowModal: (show: boolean) => void;
  addItem: (item: string) => void;
}

const Modal: FC<ModalProps> = ({ showModal, setShowModal, addItem }) => {
  const [inputValue, setInputValue] = useState<string>("");
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const items = ["Juan Carlos", "María Lupe"]; // Lista de elementos para autocompletar

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setInputValue(value);

    if (value.length > 0) {
      const filteredSuggestions = items.filter((item) => item.toLowerCase().includes(value.toLowerCase()));
      setSuggestions(filteredSuggestions);
    } else {
      setSuggestions([]);
    }
  };

  const handleAdd = () => {
    addItem(inputValue);
    setInputValue("");
    setSuggestions([]);
    setShowModal(false);
  };

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
        />
        {suggestions.length > 0 && (
          <ul className="border border-gray-300 rounded mb-2">
            {suggestions.map((suggestion, index) => (
              <li
                key={index}
                className="p-2 cursor-pointer hover:bg-gray-200"
                onClick={() => {
                  setInputValue(suggestion);
                  setSuggestions([]);
                }}>
                {suggestion}
              </li>
            ))}
          </ul>
        )}
        <div className="flex justify-end">
          <button className="bg-white text-gray px-4 py-2 " onClick={() => setShowModal(false)}>
            Cancel
          </button>
          <button className="bg-green-400 text-white px-8 py-2 rounded-lg mr-2" onClick={handleAdd}>
            Add
          </button>
        </div>
      </div>
    </div>
  );
};

export default Modal;
