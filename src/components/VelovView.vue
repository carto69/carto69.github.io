<template>
  <div class="velov-page">
    <aside class="velov-controls">
      <button class="back" @click="$emit('back')">← Retour</button>
      <h1>69 en velo'v</h1>
      
      <div v-if="isLoading" class="loading">
        <p>Chargement des trajets...</p>
      </div>

      <div v-else-if="error" class="error">
        {{ error }}
      </div>

      <div v-else class="controls">
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

        <div class="data-tools">
          <h3>Données</h3>
          <div class="data-actions">
            <button class="btn btn-small" @click="openImportTool">Ouvrir l'outil d'import</button>
            <label class="btn btn-small file-label">
              Charger un JSON
              <input type="file" accept="application/json" @change="onFileSelected" />
            </label>
          </div>
          <div class="muted" v-if="localTripsMeta">
            Données locales: {{ localTripsMeta.count }} trajets — {{ formatDate(localTripsMeta.updatedAt) }}
            <div class="data-actions-inline">
              <button class="btn btn-small" @click="useLocalTrips" :disabled="isUsingLocal">Utiliser</button>
              <button class="btn btn-small" @click="clearLocalTrips" :disabled="!isUsingLocal">Réinitialiser</button>
            </div>
          </div>
        </div>

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
      isLoading: true,
      error: null,
      trips: [],
      selectedTrip: null,
      showRoutes: true,
      showHeatmap: false,
      isUsingLocal: false
    }
  },
  computed: {
    localTripsMeta() {
      try {
        const raw = localStorage.getItem('velovTrips')
        if (!raw) return null
        const parsed = JSON.parse(raw)
        if (!parsed || !Array.isArray(parsed.trips)) return null
        return { count: parsed.count ?? parsed.trips.length, updatedAt: parsed.updatedAt }
      } catch { return null }
    },
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
    
    // Charger les données depuis le fichier JSON
    this.loadTrips()
  },
  beforeUnmount() {
    if (this.map) {
      this.map.remove()
    }
  },
  methods: {
    async loadTrips() {
      this.isLoading = true
      this.error = null

      try {
        // 1) Préférer les données locales si présentes
        const local = this.getLocalTrips()
        if (local) {
          this.trips = local
          this.isUsingLocal = true
          this.updateMap()
          return
        }

        // 2) Sinon, charger le fichier embarqué
        const response = await fetch('/velov-trips.json')
        
        if (!response.ok) {
          throw new Error('Impossible de charger les données VeloV')
        }

        this.trips = await response.json()
        
        if (this.trips.length === 0) {
          this.error = 'Aucun trajet trouvé. Utilisez export-velov.html pour exporter vos données.'
        } else {
          this.updateMap()
        }
      } catch (error) {
        this.error = error.message
        console.error('Load error:', error)
      } finally {
        this.isLoading = false
      }
    },

    openImportTool() {
      window.open('/import-velov.html', '_blank')
    },

    onFileSelected(e) {
      const file = e.target.files?.[0]
      if (!file) return
      const reader = new FileReader()
      reader.onload = () => {
        try {
          const text = String(reader.result || '')
          const json = JSON.parse(text)
          if (!Array.isArray(json)) throw new Error('Fichier invalide: attendu un tableau de trajets')
          this.trips = json
          this.isUsingLocal = true
          this.saveLocalTrips(json)
          this.updateMap()
        } catch (err) {
          this.error = 'Fichier JSON invalide'
          console.error(err)
        }
      }
      reader.readAsText(file)
      // reset input for re-selecting the same file later
      e.target.value = ''
    },

    saveLocalTrips(trips) {
      try {
        const payload = { updatedAt: new Date().toISOString(), count: trips.length, trips }
        localStorage.setItem('velovTrips', JSON.stringify(payload))
      } catch {}
    },

    getLocalTrips() {
      try {
        const raw = localStorage.getItem('velovTrips')
        if (!raw) return null
        const parsed = JSON.parse(raw)
        if (!parsed || !Array.isArray(parsed.trips)) return null
        return parsed.trips
      } catch { return null }
    },

    useLocalTrips() {
      const local = this.getLocalTrips()
      if (local) {
        this.trips = local
        this.isUsingLocal = true
        this.updateMap()
      }
    },

    clearLocalTrips() {
      try { localStorage.removeItem('velovTrips') } catch {}
      this.isUsingLocal = false
      // Recharger depuis le fichier embarqué
      this.loadTrips()
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
      this.map.addControl(new mapboxgl.ScaleControl({ unit: 'metric' }), 'bottom-right')
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

.data-tools .data-actions { display: flex; gap: 8px; margin: 6px 0; }
.data-tools .data-actions-inline { display: flex; gap: 8px; margin-top: 8px; }
.file-label { position: relative; overflow: hidden; }
.file-label input[type="file"] { position: absolute; inset: 0; opacity: 0; cursor: pointer; }
.muted { color: #666; font-size: 12px; }

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
