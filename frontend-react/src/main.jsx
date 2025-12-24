/**
 * React 应用入口文件
 * 渲染根组件到 DOM
 */
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";

// React 应用入口；StrictMode 在开发模式下启用额外检查
ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
