const LoadingSpinner = () => (
  <svg className="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V4a10 10 0 00-10 10h2zm0 0a8 8 0 008 8v-2a10 10 0 01-10-10h2zm0 0a8 8 0 018 8h-2a10 10 0 00-10-10v2z"></path>
  </svg>
);

export default LoadingSpinner;
