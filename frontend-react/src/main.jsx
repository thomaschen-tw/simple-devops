import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";

// Entry point for the React app; StrictMode enables extra checks in dev.
ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);

