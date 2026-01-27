import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  base: '/carto69/',
  plugins: [vue()],
  external: ['mapbox-gl'],
  build: {
    rollupOptions: {
      external: ['mapbox-gl'],
      output: {
        globals: {
          'mapbox-gl': 'mapboxgl'
        }
      }
    }
  },
  server: {
    host: true,
    proxy: {
      '/api-proxy': {
        target: 'https://api.cyclocity.fr',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api-proxy/, '')
      }
    }
  }
})
