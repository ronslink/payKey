import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  // Ensure we pick up the Docker backend URL explicitly if present in env vars
  const apiTarget = process.env.VITE_API_URL || env.VITE_API_URL || 'http://backend:3000'
  console.log('Vite Proxy API Target resolved to:', apiTarget);

  return {
    plugins: [react()],
    server: {
      host: '0.0.0.0', // Required for Docker
      port: 5174,
      proxy: {
        '/api/auth': {
          target: apiTarget,
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/api\/auth/, '/auth'),
        },
        '/api': {
          target: apiTarget,
          changeOrigin: true,
        },
      },
    },
    build: {
      outDir: 'dist',
      sourcemap: false,
    },
  }
})


