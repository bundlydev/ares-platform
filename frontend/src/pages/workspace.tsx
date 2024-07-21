import React, { useState } from "react";

import Modal from "../components/Modal";
import SelectWorkspace from "../components/SelectWorkspace";

export default function Workspace() {
  const [image, setImage] = useState<File | null>(null);

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
  return (
    <div className=" flex justify-center">
      <div className=" flex flex-col w-1/4 pt-40 gap-y-8">
        <span className="text-4xl font-semibold">New workspace</span>
        <input
          type="text"
          placeholder="Type name"
          className="h-10 w-11/12 rounded-lg border border-gray-300 px-2"
        />
        <div
          className="w-11/12 h-40 border-2 border-dashed border-gray-300 rounded-lg flex items-center justify-center"
          onDrop={handleDrop}
          onDragOver={handleDragOver}>
          <input type="file" className="hidden" onChange={handleImageChange} />
          {!image ? <p>Drag an image here </p> : <p>{image.name}</p>}
        </div>
        <button
        className="bg-green-400 w-11/12 text-white px-8 py-2 rounded-lg mb-4"
      >
        Create Workspace
      </button>
      </div>
    </div>
  );
}
