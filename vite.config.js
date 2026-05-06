import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

export default defineConfig({
  plugins: [
    vue(),
    vueDevTools(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    },
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, '/FastFoodYumMy/api')
      }
    },
    allowedHosts: [
      'vixen-error-reentry.ngrok-free.dev', // Add this to allow the blocked host
      'localhost', // You can add other hosts as needed
      '127.0.0.1',
      'your-ngrok-url.ngrok.io' // Add if you're using ngrok for other services
    ]
  }
})