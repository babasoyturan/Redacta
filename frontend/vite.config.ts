import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";

export default defineConfig({
  server: {
    host: "::",
    port: 5173,
    proxy: {
      "/api/v1/documents": {
        target: "http://localhost:8091",
        changeOrigin: true,
      },
      "/api/v1/authentication": {
        target: "http://localhost:8092",
        changeOrigin: true,
      },
      "/api/v1/anonymization": {
        target: "http://localhost:8094",
        changeOrigin: true,
      },
      "/api/v1/genai": {
        target: "http://localhost:8000",
        changeOrigin: true,
      },
    },
  },
  plugins: [react()],
  resolve: {
    alias: { "@": path.resolve(__dirname, "./src") },
  },
});
