<template>
  <div class="velib-page">
    <aside class="velib-controls">
      <button class="back" @click="$emit('back')">← Retour</button>
      <h1>75 en vélib'</h1>
      
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
      <div v-if="selectedTrip" class="trip-popup">
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
  name: 'VelibView',
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
        const raw = localStorage.getItem('velibTrips')
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
        const response = await fetch('/velib-trips.json')
        
        if (!response.ok) {
          throw new Error('Aucune donnée Vélib\' trouvée. Chargez vos données via le bouton ci-dessus.')
        }

        this.trips = await response.json()
        
        if (this.trips.length === 0) {
          this.error = 'Aucun trajet trouvé. Chargez vos données Vélib\' via le bouton ci-dessus.'
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
        localStorage.setItem('velibTrips', JSON.stringify(payload))
      } catch {}
    },

    getLocalTrips() {
      try {
        const raw = localStorage.getItem('velibTrips')
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
      try { localStorage.removeItem('velibTrips') } catch {}
      this.isUsingLocal = false
      // Recharger depuis le fichier embarqué
      this.loadTrips()
    },

    initMap() {
      this.map = new mapboxgl.Map({
        container: this.$refs.mapContainer,
        style: 'mapbox://styles/mapbox/streets-v12',
        center: [2.3522, 48.8566], // Paris
        zoom: 11
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
              6, 1
            ],
            'heatmap-intensity': [
              'interpolate',
              ['linear'],
              ['zoom'],
              0, 1,
              15, 3
            ],
            'heatmap-color': [
              'interpolate',
              ['linear'],
              ['heatmap-density'],
              0, 'rgba(0, 0, 255, 0)',
              0.1, 'royalblue',
              0.3, 'cyan',
              0.5, 'lime',
              0.7, 'yellow',
              1, 'red'
            ],
            'heatmap-radius': [
              'interpolate',
              ['linear'],
              ['zoom'],
              0, 2,
              15, 20
            ],
            'heatmap-opacity': 0.8
          }
        })

        this.map.addControl(new mapboxgl.NavigationControl())
        
        this.updateMap()
      })
    },

    updateMap() {
      if (!this.map || !this.map.getSource('routes-source')) return

      // Mettre à jour les données
      const routesData = createRoutesData(this.trips)
      const heatmapData = createHeatmapData(this.trips)

      this.map.getSource('routes-source').setData(routesData)
      this.map.getSource('heatmap-source').setData(heatmapData)

      // Gérer la visibilité
      this.map.setLayoutProperty(
        'routes-layer',
        'visibility',
        this.showRoutes ? 'visible' : 'none'
      )
      this.map.setLayoutProperty(
        'heatmap-layer',
        'visibility',
        this.showHeatmap ? 'visible' : 'none'
      )
    },

    selectTrip(trip) {
      this.selectedTrip = trip
      if (trip.startStation?.lat && trip.startStation?.lng) {
        this.map.flyTo({
          center: [trip.startStation.lng, trip.startStation.lat],
          zoom: 14
        })
      }
    },

    formatDate(isoString) {
      if (!isoString) return ''
      const d = new Date(isoString)
      return d.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' })
    },

    formatDuration(minutes) {
      const h = Math.floor(minutes / 60)
      const m = minutes % 60
      return h > 0 ? `${h}h ${m}m` : `${m}m`
    },

    haversineDistance(lat1, lon1, lat2, lon2) {
      const R = 6371 // rayon de la Terre en km
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
.velib-page {
  display: flex;
  width: 100%;
  height: 100vh;
}

.velib-controls {
  width: 360px;
  height: 100%;
  background: #f9f9f9;
  border-right: 1px solid #ddd;
  overflow-y: auto;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.back {
  background: #2171b5;
  color: white;
  border: none;
  padding: 10px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  margin-bottom: 10px;
}

.back:hover {
  background: #1a5a8e;
}

h1 {
  font-size: 1.8rem;
  font-weight: 700;
  margin: 0 0 10px 0;
  color: #333;
}

hr {
  border: none;
  border-top: 1px solid #ddd;
  margin: 10px 0;
}

.loading, .error {
  padding: 20px;
  text-align: center;
  background: #fff;
  border-radius: 8px;
}

.error {
  color: #d32f2f;
}

.controls {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.trip-stats h3,
.data-tools h3,
.visualization-controls h3,
.trip-list h3 {
  font-size: 1rem;
  margin: 0 0 8px 0;
  color: #555;
}

.trip-stats p {
  margin: 4px 0;
  font-size: 0.95rem;
}

.data-tools {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.data-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.data-actions-inline {
  display: flex;
  gap: 8px;
  margin-top: 6px;
}

.btn {
  background: #2171b5;
  color: white;
  border: none;
  padding: 8px 12px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
}

.btn:hover {
  background: #1a5a8e;
}

.btn:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.btn-small {
  padding: 6px 10px;
  font-size: 0.85rem;
}

.file-label {
  position: relative;
  display: inline-block;
}

.file-label input[type="file"] {
  position: absolute;
  opacity: 0;
  width: 0;
  height: 0;
}

.muted {
  font-size: 0.85rem;
  color: #666;
  background: #fff;
  padding: 8px;
  border-radius: 4px;
}

.visualization-controls {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.95rem;
  cursor: pointer;
}

.checkbox-label input[type="checkbox"] {
  width: 18px;
  height: 18px;
  cursor: pointer;
}

.trip-list {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0;
}

.scroll-container {
  flex: 1;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.trip-item {
  background: #fff;
  padding: 10px;
  border-radius: 6px;
  cursor: pointer;
  border: 2px solid transparent;
  transition: all 0.2s;
}

.trip-item:hover {
  border-color: #2171b5;
}

.trip-item.active {
  background: #e3f2fd;
  border-color: #2171b5;
}

.trip-item .arrow {
  color: #2171b5;
  font-weight: bold;
  margin: 0 4px;
}

.trip-item small {
  color: #666;
  font-size: 0.85rem;
}

.map-container {
  flex: 1;
  position: relative;
}

.trip-popup {
  position: absolute;
  top: 20px;
  left: 20px;
  background: white;
  padding: 12px 16px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
  z-index: 1;
  max-width: 300px;
}

.trip-popup .arrow {
  color: #2171b5;
  margin: 0 4px;
}

.trip-popup p {
  margin: 4px 0;
  font-size: 0.9rem;
}
</style>
