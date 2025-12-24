/**
 * Vite 配置文件
 * 配置 React 应用构建和开发服务器
 */
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,  // 开发服务器端口
  },
});
