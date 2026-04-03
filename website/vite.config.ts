import { defineConfig } from "vite";
import solid from "vite-plugin-solid";
import devtools from "solid-devtools/vite";

export default defineConfig({
  plugins: [
    devtools({
      autoname: true,
    }),
    solid(),
  ],
  build: {
    sourcemap: true,
    manifest: true,
  },
  server: {
    cors: {
      origin: "https://localhost:3000",
    },
    port: 5173,
    strictPort: true,
    hmr: {
      port: 5173,
      clientPort: 5173,
      protocol: "ws",
    },
  },
  resolve: {
    alias: {
      "@": "/src",
    },
  },
  optimizeDeps: {
    // solid-chartjs because I have a local fork
    // chartjs-adapter-moment because for some reason it breaks otherwise
    exclude: ["solid-chartjs", "chartjs-adapter-date-fns"],
  },
});
