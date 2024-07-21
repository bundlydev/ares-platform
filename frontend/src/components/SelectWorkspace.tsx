import React, { useState } from 'react';
import { useRouter } from 'next/router';

const SelectWorkspace: React.FC = () => {
    const router = useRouter();
    const [selectedOption, setSelectedOption] = useState<string | null>('ESPACIO 1');
    const [options, setOptions] = useState<string[]>(['ESPACIO 1', 'ESPACIO 2']);
    const [isDropdownOpen, setIsDropdownOpen] = useState<boolean>(false);

    const handleOptionClick = (option: string) => {
        setSelectedOption(option);
        setIsDropdownOpen(false);
    };

    const handleAddClick = () => {
        setIsDropdownOpen(false);
        router.push('/workspace');
    };

    return (
        <div className="relative inline-block text-left">
            <div>
                <button
                    type="button"
                    className="inline-flex justify-between w-56 rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"
                    onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                >
                    {selectedOption || 'Selecciona un espacio'}
                    <svg
                        className="-mr-1 ml-2 h-5 w-5"
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        aria-hidden="true"
                    >
                        <path
                            fillRule="evenodd"
                            d="M10 3a1 1 0 01.832.445l7 10A1 1 0 0117 15H3a1 1 0 01-.832-1.555l7-10A1 1 0 0110 3zm0 2.236L4.618 14h10.764L10 5.236z"
                            clipRule="evenodd"
                        />
                    </svg>
                </button>
            </div>
            {isDropdownOpen && (
                <div className="origin-top-right absolute right-0 mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5">
                    <div className="py-1" role="menu" aria-orientation="vertical" aria-labelledby="options-menu">
                        {options.map((option, index) => (
                            <div
                                key={index}
                                onClick={() => handleOptionClick(option)}
                                className="cursor-pointer block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                                role="menuitem"
                            >
                                {option}
                            </div>
                        ))}
                        <div
                            onClick={handleAddClick}
                            className="cursor-pointer block px-4 py-2 text-sm text-blue-500 hover:bg-gray-100"
                            role="menuitem"
                        >
                            Create Workspace
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default SelectWorkspace;
