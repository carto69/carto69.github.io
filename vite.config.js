import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    host: true
  },
  build: {
    rollupOptions: {
      external: [
        'mapbox-gl',
        'mapbox-gl/dist/mapbox-gl.css'
      ],
      output: {
        globals: {
          'mapbox-gl': 'mapboxgl',
          'mapbox-gl/dist/mapbox-gl.css': 'mapboxGlCss'
        }
      }
    },
    commonjsOptions: {
      include: [/node_modules/]
    }
  }
})
