import React, { useState } from "react";
import { useAuthGuard } from "@app/hooks/useGuard";

import Modal from "../components/Modal";
import ModalDelete from '../components/ModalDelete';
import SelectWorkspace from "../components/SelectWorkspace";

export default function Home() {
  const Name = "Christian Cadena";
  const [showModal, setShowModal] = useState<boolean>(false);
  const [showModalDelete, setShowModalDelete] = useState<boolean>(false);
  const [deleteItem, setDeleteItem] = useState<string>('');
  const [items, setItems] = useState<string[]>(["Juan Pérez", "María López"]);
	useAuthGuard({ isPrivate: true });
  const addItem = (item: string) => {
    setItems([...items, item]);
  };
  const data = [
    { name: "Juan Pérez", role: "Admin", action: "Delete" },
    { name: "María López", role: "Super Admin", action: "Delete" },
  ];
  return (
    <div className=" flex flex-col">
      <div className="flex h-16 bg-cyan-950 items-center justify-between px-2">
        <div className="flex w-1/4 justify-around">
        <div className="flex bg-cyan-600 rounded-full h-9 w-9  items-center justify-center">
          <span className="text-white">{Name[0]}</span>
        </div>
        <SelectWorkspace />
        </div>
        <div className="flex bg-cyan-600 rounded-full h-9 w-9  items-center justify-center">
          <span className="text-white">{Name[0]}</span>
        </div>
      </div>
      <div className="flex ">
        <div className="container mx-auto mt-10 flex flex-col justify-end items-end">
          <button
            className="bg-green-400 text-white px-8 py-2 rounded-lg mb-4 w-36"
            onClick={() => setShowModal(true)}>
            New
          </button>
          <div className="bg-white shadow-md rounded-lg overflow-hidden w-10/12">
            <div className="grid grid-cols-3 bg-gray-200 p-4 text-gray-700 font-bold">
              <div>Name</div>
              <div>Role</div>
              <div>Action</div>
            </div>
            <div className="divide-y divide-gray-200">
              {items.map((item, index) => (
                <div key={index} className="grid grid-cols-3 p-4">
                  <div>{item}</div>
                  <div>Admin</div>
                  <div>
                    <button className="bg-red-500 text-white py-1 px-3 rounded-lg" onClick={() => {setShowModalDelete(true),setDeleteItem(item)}}>Eliminar</button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
      <Modal showModal={showModal} setShowModal={setShowModal} addItem={addItem} />
      <ModalDelete showModalDelete={showModalDelete} setShowModalDelete={setShowModalDelete} deleteItem={deleteItem} />
    </div>
  );
}
