<template>
  <div class="velov-page">
    <aside class="velov-controls">
      <button class="back" @click="$emit('back')">← Retour</button>
      <h1>69 en velo'v</h1>
      
      <div v-if="!isAuthenticated" class="auth-form">
        <input 
          v-model="email" 
          type="email" 
          placeholder="Email" 
          class="input"
          @keyup.enter="login"
        />
        <input 
          v-model="password" 
          type="password" 
          placeholder="Mot de passe" 
          class="input"
          @keyup.enter="login"
        />
        <button @click="login" :disabled="isLoading" class="btn btn-primary">
          {{ isLoading ? 'Chargement...' : 'Se connecter' }}
        </button>
        <div v-if="error" class="error">{{ error }}</div>
      </div>

      <div v-else class="controls">
        <div class="user-info">
          <p>Connecté en tant que: <strong>{{ email }}</strong></p>
          <button @click="logout" class="btn btn-small">Déconnecter</button>
        </div>

        <hr />

        <div class="trip-stats">
          <h3>Statistiques</h3>
          <p>Trajets total: <strong>{{ trips.length }}</strong></p>
          <p v-if="trips.length > 0">
            Distance totale: <strong>{{ totalDistance.toFixed(1) }} km</strong>
          </p>
          <p v-if="trips.length > 0">
            Temps total: <strong>{{ totalDuration }}</strong>
          </p>
        </div>

        <hr />

        <div class="visualization-controls">
          <h3>Visualisation</h3>
          <label class="checkbox-label">
            <input 
              v-model="showRoutes" 
              type="checkbox"
              @change="updateMap"
            />
            Trajets individuels
          </label>
          <label class="checkbox-label">
            <input 
              v-model="showHeatmap" 
              type="checkbox"
              @change="updateMap"
            />
            Heatmap
          </label>
        </div>

        <div v-if="trips.length > 0" class="trip-list">
          <h3>Trajets</h3>
          <div class="scroll-container">
            <div 
              v-for="trip in trips" 
              :key="trip.id"
              class="trip-item"
              @click="selectTrip(trip)"
              :class="{ active: selectedTrip?.id === trip.id }"
            >
              <strong>{{ trip.startStation?.name }}</strong>
              <span class="arrow">→</span>
              <strong>{{ trip.endStation?.name }}</strong>
              <br />
              <small>{{ formatDate(trip.startTime) }}</small>
            </div>
          </div>
        </div>
      </div>
    </aside>

    <div ref="mapContainer" class="map-container">
      <div v-if="selectedTrip && isAuthenticated" class="trip-popup">
        <strong>{{ selectedTrip.startStation?.name }}</strong>
        <span class="arrow">→</span>
        <strong>{{ selectedTrip.endStation?.name }}</strong>
        <p>Durée: {{ formatDuration(selectedTrip.duration) }}</p>
        <p>Type: {{ selectedTrip.bikeType }}</p>
      </div>
    </div>
  </div>
</template>

<script>
const mapboxgl = window.mapboxgl
import { createHeatmapData, createRoutesData } from '../utils/heatmap'

export default {
  name: 'VelovView',
  data() {
    return {
      map: null,
      email: '',
      password: '',
      isAuthenticated: false,
      isLoading: false,
      error: null,
      trips: [],
      selectedTrip: null,
      showRoutes: true,
      showHeatmap: false
    }
  },
  computed: {
    totalDistance() {
      // Approximation: distance entre stations (Haversine)
      return this.trips.reduce((sum, trip) => {
        if (!trip.startStation || !trip.endStation) return sum
        const dist = this.haversineDistance(
          trip.startStation.lat,
          trip.startStation.lng,
          trip.endStation.lat,
          trip.endStation.lng
        )
        return sum + dist
      }, 0)
    },
    totalDuration() {
      const minutes = this.trips.reduce((sum, trip) => sum + (trip.duration || 0), 0)
      const hours = Math.floor(minutes / 60)
      const mins = minutes % 60
      return `${hours}h ${mins}m`
    }
  },
  mounted() {
    const token = import.meta.env.VITE_MAPBOX_TOKEN
    if (token) {
      mapboxgl.accessToken = token
      this.initMap()
    }
    
    // Auto-login avec les identifiants de l'environnement
    const velovEmail = import.meta.env.VITE_VELOV_EMAIL
    const velovPassword = import.meta.env.VITE_VELOV_PASSWORD
    
    if (velovEmail && velovPassword) {
      this.email = velovEmail
      this.password = velovPassword
      this.login()
    }
  },
  beforeUnmount() {
    if (this.map) {
      this.map.remove()
    }
  },
  methods: {
    async login() {
      if (!this.email || !this.password) {
        this.error = 'Veuillez entrer votre email et mot de passe'
        return
      }

      this.isLoading = true
      this.error = null

      try {
        const response = await fetch('/api/trips', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            email: this.email,
            password: this.password
          })
        })

        if (!response.ok) {
          const data = await response.json()
          throw new Error(data.error || 'Erreur d\'authentification')
        }

        const data = await response.json()
        this.trips = data.trips || []
        this.isAuthenticated = true
        this.updateMap()
      } catch (error) {
        this.error = error.message
        console.error('Login error:', error)
      } finally {
        this.isLoading = false
      }
    },

    logout() {
      this.isAuthenticated = false
      this.email = ''
      this.password = ''
      this.trips = []
      this.selectedTrip = null
      this.clearMap()
    },

    initMap() {
      this.map = new mapboxgl.Map({
        container: this.$refs.mapContainer,
        style: 'mapbox://styles/mapbox/streets-v12',
        center: [4.8357, 45.7640], // Lyon
        zoom: 12
      })

      this.map.on('load', () => {
        // Ajouter les sources pour routes et heatmap
        this.map.addSource('routes-source', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features: [] }
        })

        this.map.addSource('heatmap-source', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features: [] }
        })

        // Ajouter les layers
        this.map.addLayer({
          id: 'routes-layer',
          type: 'line',
          source: 'routes-source',
          paint: {
            'line-color': '#2171b5',
            'line-width': 2,
            'line-opacity': 0.7
          }
        })

        this.map.addLayer({
          id: 'heatmap-layer',
          type: 'heatmap',
          source: 'heatmap-source',
          paint: {
            'heatmap-weight': [
              'interpolate',
              ['linear'],
              ['get', 'intensity'],
              0, 0,
              1, 1
            ],
            'heatmap-intensity': [
              'interpolate',
              ['linear'],
              ['zoom'],
              0, 1,
              9, 3
            ],
            'heatmap-color': [
              'interpolate',
              ['linear'],
              ['heatmap-density'],
              0, 'rgba(33, 102, 172, 0)',
              0.2, 'rgb(103, 169, 207)',
              0.4, 'rgb(209, 229, 240)',
              0.6, 'rgb(253, 219, 199)',
              0.8, 'rgb(239, 138, 98)',
              1, 'rgb(178, 24, 43)'
            ],
            'heatmap-radius': [
              'interpolate',
              ['linear'],
              ['zoom'],
              0, 2,
              9, 20
            ],
            'heatmap-opacity': [
              'interpolate',
              ['linear'],
              ['zoom'],
              7, 1,
              9, 0.5
            ]
          }
        })

        this.updateMap()
      })

      // Ajouter contrôles
      this.map.addControl(new mapboxgl.NavigationControl())
    },

    updateMap() {
      if (!this.map || !this.map.isStyleLoaded()) return

      // Mettre à jour les routes
      if (this.showRoutes) {
        const routesData = createRoutesData(this.trips)
        this.map.getSource('routes-source').setData(routesData)
        this.map.setLayoutProperty('routes-layer', 'visibility', 'visible')
      } else {
        this.map.setLayoutProperty('routes-layer', 'visibility', 'none')
      }

      // Mettre à jour la heatmap
      if (this.showHeatmap) {
        const heatmapData = createHeatmapData(this.trips)
        this.map.getSource('heatmap-source').setData(heatmapData)
        this.map.setLayoutProperty('heatmap-layer', 'visibility', 'visible')
      } else {
        this.map.setLayoutProperty('heatmap-layer', 'visibility', 'none')
      }
    },

    clearMap() {
      if (this.map && this.map.isStyleLoaded()) {
        this.map.getSource('routes-source').setData({ type: 'FeatureCollection', features: [] })
        this.map.getSource('heatmap-source').setData({ type: 'FeatureCollection', features: [] })
      }
    },

    selectTrip(trip) {
      this.selectedTrip = trip
      // Centrer la map sur le trajet
      if (trip.startStation?.lat && trip.startStation?.lng) {
        this.map.flyTo({
          center: [trip.startStation.lng, trip.startStation.lat],
          zoom: 14,
          duration: 1000
        })
      }
    },

    formatDate(dateStr) {
      return new Date(dateStr).toLocaleDateString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    },

    formatDuration(minutes) {
      const hours = Math.floor(minutes / 60)
      const mins = minutes % 60
      if (hours > 0) return `${hours}h ${mins}m`
      return `${mins}m`
    },

    haversineDistance(lat1, lon1, lat2, lon2) {
      const R = 6371 // Rayon de la terre en km
      const dLat = (lat2 - lat1) * Math.PI / 180
      const dLon = (lon2 - lon1) * Math.PI / 180
      const a = 
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2)
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      return R * c
    }
  }
}
</script>

<style scoped>
.velov-page {
  display: flex;
  height: 100vh;
}

.velov-controls {
  width: 350px;
  background: white;
  padding: 20px;
  overflow-y: auto;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  position: relative;
}

.map-container {
  flex: 1;
  position: relative;
}

.back {
  position: static;
  top: auto;
  right: auto;
  background: #2171b5;
  color: white;
  border: none;
  padding: 8px 12px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
  z-index: 10;
  margin-bottom: 20px;
  width: 100%;
}

h1 {
  margin: 0 0 20px 0;
  color: #333;
  font-size: 24px;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.input {
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.btn {
  padding: 10px;
  border: none;
  border-radius: 4px;
  font-size: 14px;
  cursor: pointer;
  font-weight: 600;
}

.btn-primary {
  background: #2171b5;
  color: white;
}

.btn-primary:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.btn-small {
  background: #666;
  color: white;
  padding: 6px 12px;
  font-size: 12px;
}

.error {
  background: #fee;
  color: #c00;
  padding: 10px;
  border-radius: 4px;
  font-size: 13px;
}

.controls {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.user-info {
  background: #f0f0f0;
  padding: 12px;
  border-radius: 4px;
  font-size: 13px;
}

hr {
  border: none;
  border-top: 1px solid #ddd;
  margin: 0;
}

.trip-stats h3,
.visualization-controls h3,
.trip-list h3 {
  margin: 0 0 10px 0;
  font-size: 14px;
  color: #333;
}

.trip-stats p,
.visualization-controls label {
  font-size: 13px;
  margin: 6px 0;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.checkbox-label input {
  cursor: pointer;
}

.scroll-container {
  max-height: 300px;
  overflow-y: auto;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.trip-item {
  padding: 10px;
  border-bottom: 1px solid #eee;
  font-size: 12px;
  cursor: pointer;
  transition: background 0.2s;
}

.trip-item:hover {
  background: #f5f5f5;
}

.trip-item.active {
  background: #e3f2fd;
  border-left: 3px solid #2171b5;
}

.arrow {
  color: #999;
  margin: 0 4px;
}

small {
  color: #666;
}

.trip-popup {
  position: absolute;
  bottom: 20px;
  left: 20px;
  background: white;
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.2);
  max-width: 250px;
  font-size: 13px;
  z-index: 5;
}

.trip-popup strong {
  color: #2171b5;
}

.trip-popup p {
  margin: 6px 0 0 0;
  color: #666;
}
</style>
