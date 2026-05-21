import { defineConfig } from 'vite';

export default defineConfig({
  // For GitHub Pages deployment at:
  // https://dylntrnr.github.io/async-vdot-doxyme-app/
  base: process.env.VITE_BASE_URL || '/',
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
    rollupOptions: {
      output: {
        manualChunks: undefined,
      },
    },
  },
  server: {
    port: 5173,
    host: true,
  },
  define: {
    __DOXY_SDK_VERSION__: JSON.stringify('1.2.1'),
  },
});
