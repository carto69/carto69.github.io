<template>
  <div class="velov-container">
    <button class="back-button" @click="$emit('back')" title="Retour à l'accueil">← Accueil</button>
    <div id="velov-map" class="map-canvas"></div>
    <div class="map-title">le 69 en vélo'v</div>
    
    <!-- Barre latérale des statistiques -->
    <div class="stats-sidebar">
      <h2>Mes trajets</h2>
      
      <!-- Stats globales -->
      <div class="stat-item">
        <span class="stat-label">Trajets</span>
        <span class="stat-value">{{ stats.countTrips }}</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">Distance</span>
        <span class="stat-value">{{ stats.kmTotal }} km</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">CO₂ économisé</span>
        <span class="stat-value">{{ stats.co2Total }} kg</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">Vitesse moyenne</span>
        <span class="stat-value">{{ stats.avgSpeed }} km/h</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">Segments tracés</span>
        <span class="stat-value">{{ stats.countFeatures }}</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">Durée moyenne</span>
        <span class="stat-value">{{ stats.avgDuration }}</span>
      </div>
      
      <!-- Options de la carte -->
      <hr class="sidebar-divider" />
      <div class="map-controls" style="display: flex; flex-direction: row; align-items: center; gap: 1em; flex-wrap: wrap;">
        <label>
          <input type="checkbox" v-model="showStations" @change="toggleStations" :disabled="showHotspot" />
          Stations
        </label>
        <label>
          <input type="checkbox" v-model="showHotspot" @change="toggleHotspot" />
          Heatmap
        </label>
      </div>
      
      <!-- Sélecteur de trajet -->
      <hr class="sidebar-divider" />
      <div class="trajet-selector">
        <label>Analyser un trajet:</label>
        <select v-model="selectedTripIndex" @change="onTripSelected" class="trip-select">
          <option :value="-1">-- Sélectionner --</option>
          <option v-for="(trip, idx) in displayedTrips" :key="idx" :value="idx">
            {{ trip.idx + 1 }}. {{ trip.depName }} → {{ trip.arrName }} ({{ trip.distance }}m)
          </option>
        </select>
      </div>
      
      <!-- Détails du trajet sélectionné -->
      <div v-if="selectedTripIndex >= 0" class="trip-details">
        <div class="detail-section">
          <h3>📍 Départ</h3>
          <div class="detail-row">
            <span class="label">Station:</span>
            <span class="value">{{ selectedTrip.depName }}</span>
          </div>
          <div class="detail-row">
            <span class="label">ID:</span>
            <span class="value small">{{ selectedTrip.depId }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Coords:</span>
            <span class="value small mono">{{ selectedTrip.depCoords }}</span>
          </div>
        </div>
        
        <div class="detail-section">
          <h3>🎯 Arrivée</h3>
          <div class="detail-row">
            <span class="label">Station:</span>
            <span class="value">{{ selectedTrip.arrName }}</span>
          </div>
          <div class="detail-row">
            <span class="label">ID:</span>
            <span class="value small">{{ selectedTrip.arrId }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Coords:</span>
            <span class="value small mono">{{ selectedTrip.arrCoords }}</span>
          </div>
        </div>
        
        <div class="detail-section">
          <h3>📊 Trajet</h3>
          <div class="detail-row">
            <span class="label">Distance:</span>
            <span class="value">{{ (selectedTrip.distance / 1000).toFixed(2) }} km</span>
          </div>
          <div class="detail-row">
            <span class="label">Vitesse moy:</span>
            <span class="value">{{ selectedTrip.speed }} km/h</span>
          </div>
          <div class="detail-row">
            <span class="label">Date:</span>
            <span class="value small">{{ new Date(selectedTrip.date).toLocaleDateString('fr-FR') }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
const mapboxgl = window.mapboxgl

export default {
  name: 'VelovView',
  data() {
    return {
      trips: [],
      stations: {},
      displayedTrips: [],
      selectedTripIndex: -1,
      showStations: true,
      showHotspot: false,
      stats: {
        countTrips: 0,
        countFeatures: 0,
        kmTotal: 0,
        co2Total: 0,
        avgSpeed: 0,
        avgDuration: '0 min'
      },
      loading: true,
      error: null,
      map: null
    }
  },
  mounted() {
    this.loadTrips()
  },
  methods: {
        toggleHotspot() {
          if (!this.map) return
          if (this.showHotspot) {
            // Masquer segments et points
            if (this.map.getLayer('trips-layer')) {
              this.map.setLayoutProperty('trips-layer', 'visibility', 'none')
            }
            if (this.map.getLayer('stations-layer')) {
              this.map.setLayoutProperty('stations-layer', 'visibility', 'none')
            }
            // Afficher la heatmap
            this.displayHeatmap()
          } else {
            // Masquer la heatmap
            if (this.map.getLayer('velov-heatmap')) {
              this.map.setLayoutProperty('velov-heatmap', 'visibility', 'none')
            }
            // Réafficher segments/points selon options
            if (this.map.getLayer('trips-layer')) {
              this.map.setLayoutProperty('trips-layer', 'visibility', 'visible')
            }
            if (this.showStations && this.map.getLayer('stations-layer')) {
              this.map.setLayoutProperty('stations-layer', 'visibility', 'visible')
            }
          }
        },

        displayHeatmap() {
          if (!this.map) return
          // Construire les points de heatmap à partir des départs/arrivées
          const heatFeatures = []
          this.displayedTrips.forEach(trip => {
            // Départ
            const dep = trip.depCoords.split(',').map(Number)
            heatFeatures.push({
              type: 'Feature',
              geometry: { type: 'Point', coordinates: dep },
              properties: {}
            })
            // Arrivée
            const arr = trip.arrCoords.split(',').map(Number)
            heatFeatures.push({
              type: 'Feature',
              geometry: { type: 'Point', coordinates: arr },
              properties: {}
            })
          })
          if (!this.map.getSource('velov-heatmap')) {
            this.map.addSource('velov-heatmap', {
              type: 'geojson',
              data: { type: 'FeatureCollection', features: heatFeatures }
            })
            this.map.addLayer({
              id: 'velov-heatmap',
              type: 'heatmap',
              source: 'velov-heatmap',
              maxzoom: 15,
              paint: {
                'heatmap-weight': 1,
                'heatmap-intensity': 1.2,
                'heatmap-color': [
                  'interpolate', ['linear'], ['heatmap-density'],
                  0, 'rgba(0,0,0,0)',
                  0.2, '#22C55E',
                  0.4, '#16A34A',
                  0.6, '#166534',
                  1, '#F59E42'
                ],
                'heatmap-radius': 32,
                'heatmap-opacity': 0.8
              }
            })
          } else {
            this.map.getSource('velov-heatmap').setData({ type: 'FeatureCollection', features: heatFeatures })
            this.map.setLayoutProperty('velov-heatmap', 'visibility', 'visible')
          }
        },
    resolveStation(id) {
      if (!id) return null
      // For Velov format, we don't use IDs - just pass through
      return null
    },
    resolveStationByCoords(lng, lat) {
      if (lng == null || lat == null) return null
      const key = `${lng},${lat}`
      return this.stations[key] || null
    },
    async loadTrips() {
      try {
        const response = await fetch('/velov-trips.json')
        const data = await response.json()
        // Velov format: array of trips with embedded station info
        this.trips = Array.isArray(data) ? data : data.walletOperations || []
        console.log(`📍 ${this.trips.length} trajets chargés`)
        
        // Extract and build stations from trip data
        this.buildStationsFromTrips()
        this.initMap()
      } catch (error) {
        console.error('Erreur chargement trajets:', error)
        this.error = 'Impossible de charger les trajets'
        this.initMap()
      }
    },
    buildStationsFromTrips() {
      // Build station map from embedded station data in trips
      const stationsMap = {}
      
      this.trips.forEach(trip => {
        const startStation = trip.startStation
        const endStation = trip.endStation
        
        if (startStation && startStation.name && startStation.lng != null && startStation.lat != null) {
          const key = `${startStation.lng},${startStation.lat}`
          if (!stationsMap[key]) {
            stationsMap[key] = {
              name: startStation.name,
              coords: [startStation.lng, startStation.lat]
            }
          }
        }
        
        if (endStation && endStation.name && endStation.lng != null && endStation.lat != null) {
          const key = `${endStation.lng},${endStation.lat}`
          if (!stationsMap[key]) {
            stationsMap[key] = {
              name: endStation.name,
              coords: [endStation.lng, endStation.lat]
            }
          }
        }
      })
      
      this.stations = stationsMap
      const count = Object.keys(this.stations).length
      console.log(`✓ ${count} stations extraites des trajets`)
    },
    initMap() {
      mapboxgl.accessToken = import.meta.env.VITE_MAPBOX_TOKEN
      
      this.map = new mapboxgl.Map({
        container: 'velov-map',
        style: 'mapbox://styles/mapbox/dark-v11',
        center: [4.8357, 45.7640],
        zoom: 12
      })

      this.map.addControl(new mapboxgl.NavigationControl(), 'top-right')
      this.map.addControl(new mapboxgl.ScaleControl({ unit: 'metric' }), 'bottom-left')

      this.map.on('load', () => {
        this.displayTrips()
        this.displayStations()
        this.addTripClickHandler()
        this.loading = false
      })
    },
    displayTrips() {
      if (!this.trips.length) {
        this.stats = { countTrips: 0, countFeatures: 0, kmTotal: 0, co2Total: 0, avgSpeed: 0, avgDuration: '0 min' }
        console.warn('Aucun trajet à afficher')
        return
      }

      let totalDistance = 0
      let totalDuration = 0
      let validTripsCount = 0
      
      // Velov format: calculate distance from coords
      this.trips.forEach(trip => {
        if (trip.startStation && trip.endStation && trip.duration) {
          validTripsCount++
          totalDuration += trip.duration * 60 // Convert minutes to seconds
          
          // Haversine distance
          const dist = this.haversineDistance(
            trip.startStation.lat,
            trip.startStation.lng,
            trip.endStation.lat,
            trip.endStation.lng
          )
          totalDistance += dist * 1000 // Convert to meters
        }
      })
      
      const avgDurationSeconds = validTripsCount > 0 ? totalDuration / validTripsCount : 0
      const avgDurationMin = Math.round(avgDurationSeconds / 60)

      const features = []
      this.displayedTrips = []
      
      console.group('🗺️ VELOV MAP DEBUG')
      console.log(`Nombre total de trajets: ${this.trips.length}`)
      console.log(`Nombre total de stations: ${Object.keys(this.stations).length}`)
      
      this.trips.forEach((trip, idx) => {
        const startStn = trip.startStation
        const endStn = trip.endStation
        
        if (startStn && endStn && startStn.lng != null && startStn.lat != null && endStn.lng != null && endStn.lat != null) {
          const dist = this.haversineDistance(startStn.lat, startStn.lng, endStn.lat, endStn.lng)
          
          const displayTrip = {
            idx: idx,
            depId: startStn.name,
            arrId: endStn.name,
            depName: startStn.name,
            arrName: endStn.name,
            depCoords: `${startStn.lng}, ${startStn.lat}`,
            arrCoords: `${endStn.lng}, ${endStn.lat}`,
            distance: dist * 1000, // meters
            speed: trip.bikeType || 'classic',
            date: trip.startTime,
            co2: 0
          }
          
          this.displayedTrips.push(displayTrip)
          
          features.push({
            type: 'Feature',
            geometry: {
              type: 'LineString',
              coordinates: [[startStn.lng, startStn.lat], [endStn.lng, endStn.lat]]
            },
            properties: {
              distance: dist * 1000,
              date: trip.startTime,
              bikeType: trip.bikeType,
              depName: startStn.name,
              arrName: endStn.name
            }
          })
        }
      })
      
      console.log(`\n✅ ${features.length} features créées`)
      if (features.length > 0) {
        console.log(`Premier segment GeoJSON:`, features[0])
      }
      console.groupEnd()

      this.stats = {
        countTrips: this.trips.length,
        countFeatures: features.length,
        kmTotal: (totalDistance / 1000).toFixed(1),
        co2Total: '0',
        avgSpeed: '0',
        avgDuration: `${avgDurationMin} min`
      }

      console.log(`📊 ${features.length}/${this.trips.length} trajets valides | ${this.stats.kmTotal}km`)

      if (features.length > 0) {
        this.map.addSource('trips', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features }
        })

        this.map.addLayer({
          id: 'trips-layer',
          type: 'line',
          source: 'trips',
          paint: {
            'line-color': '#22C55E',
            'line-width': 3,
            'line-opacity': 0.8
          },
          layout: {
            'visibility': this.showHotspot ? 'none' : 'visible'
          }
        })

        // Masquer la heatmap si elle existe
        if (this.map.getLayer('velov-heatmap')) {
          this.map.setLayoutProperty('velov-heatmap', 'visibility', 'none')
        }

        console.log(`✓ ${features.length} trajets affichés sur la carte`)
      } else {
        console.warn('⚠️ Aucun segment valide')
      }

      const coords = []
      features.forEach(f => {
        f.geometry.coordinates.forEach(c => coords.push(c))
      })
      
      if (coords.length > 0) {
        const lons = coords.map(c => c[0])
        const lats = coords.map(c => c[1])
        const bounds = [[Math.min(...lons), Math.min(...lats)], [Math.max(...lons), Math.max(...lats)]]
        this.map.fitBounds(bounds, { padding: 120, maxZoom: 13, duration: 1000 })
      } else {
        this.map.setCenter([4.8357, 45.7640])
        this.map.setZoom(11)
      }
    },
    haversineDistance(lat1, lon1, lat2, lon2) {
      const R = 6371 // Earth radius in km
      const dLat = (lat2 - lat1) * Math.PI / 180
      const dLon = (lon2 - lon1) * Math.PI / 180
      const a = 
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2)
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      return R * c
    },
    displayStations() {
      if (!this.map || !this.showStations) return
      
      const stationFeatures = []
      
      // Create unique station points from trips
      this.displayedTrips.forEach(trip => {
        stationFeatures.push({
          type: 'Feature',
          geometry: { type: 'Point', coordinates: trip.depCoords.split(', ').map(Number) },
          properties: { name: trip.depName }
        })
        
        stationFeatures.push({
          type: 'Feature',
          geometry: { type: 'Point', coordinates: trip.arrCoords.split(', ').map(Number) },
          properties: { name: trip.arrName }
        })
      })
      
      if (stationFeatures.length === 0) return
      
      if (!this.map.getSource('stations')) {
        this.map.addSource('stations', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features: stationFeatures }
        })
        
        this.map.addLayer({
          id: 'stations-layer',
          type: 'circle',
          source: 'stations',
          paint: {
            'circle-radius': 5,
            'circle-color': '#22C55E',
            'circle-opacity': 0.8,
            'circle-stroke-width': 2,
            'circle-stroke-color': '#fff'
          }
        })
        
        const popup = new mapboxgl.Popup({ closeButton: false, closeOnClick: false })
        
        this.map.on('mouseenter', 'stations-layer', (e) => {
          this.map.getCanvas().style.cursor = 'pointer'
          const props = e.features[0].properties
          popup.setLngLat(e.lngLat)
            .setHTML(`<div style="color: #22C55E; font-size: 12px; font-weight: 600;">${props.name}</div>`)
            .addTo(this.map)
        })
        
        this.map.on('mouseleave', 'stations-layer', () => {
          this.map.getCanvas().style.cursor = ''
          popup.remove()
        })
      }
    },
    toggleStations() {
      if (!this.map) return
      if (this.showStations) {
        if (this.map.getLayer('stations-layer')) {
          this.map.setLayoutProperty('stations-layer', 'visibility', 'visible')
        } else {
          this.displayStations()
        }
      } else {
        if (this.map.getLayer('stations-layer')) {
          this.map.setLayoutProperty('stations-layer', 'visibility', 'none')
        }
      }
    },
    addTripClickHandler() {
      if (!this.map || !this.map.getLayer('trips-layer')) return
      
      this.map.on('click', 'trips-layer', (e) => {
        if (!e.features || e.features.length === 0) return
        const props = e.features[0].properties
        // Recherche stricte sur depName, arrName ET distance (évite collisions)
        const tripIdx = this.displayedTrips.findIndex(
          trip => trip.depName === props.depName && trip.arrName === props.arrName && Math.abs(trip.distance - props.distance) < 2
        )
        if (tripIdx >= 0) {
          this.selectedTripIndex = tripIdx
          this.onTripSelected()
        }
      })
      
      this.map.on('mouseenter', 'trips-layer', () => {
        this.map.getCanvas().style.cursor = 'pointer'
      })
      this.map.on('mouseleave', 'trips-layer', () => {
        this.map.getCanvas().style.cursor = ''
      })
    },
    onTripSelected() {
      if (!this.map || this.selectedTripIndex < 0) {
        if (this.map && this.map.getLayer('trips-highlight')) {
          this.map.setPaintProperty('trips-highlight', 'line-opacity', 0)
        }
        return
      }
      
      const trip = this.selectedTrip
      if (!trip) return
      
      const highlightFeature = {
        type: 'FeatureCollection',
        features: [{
          type: 'Feature',
          geometry: {
            type: 'LineString',
            coordinates: [
              trip.depCoords.split(', ').map(Number),
              trip.arrCoords.split(', ').map(Number)
            ]
          }
        }]
      }
      
      if (!this.map.getSource('trips-highlight')) {
        this.map.addSource('trips-highlight', {
          type: 'geojson',
          data: highlightFeature
        })
        
        this.map.addLayer({
          id: 'trips-highlight',
          type: 'line',
          source: 'trips-highlight',
          paint: {
            'line-color': '#FFD700',
            'line-width': 6,
            'line-opacity': 0.9,
            'line-blur': 2
          }
        }, 'trips-layer')
      } else {
        this.map.getSource('trips-highlight').setData(highlightFeature)
        this.map.setPaintProperty('trips-highlight', 'line-opacity', 0.9)
      }
      
      const depCoords = trip.depCoords.split(', ').map(Number)
      const arrCoords = trip.arrCoords.split(', ').map(Number)
      const bounds = [
        [Math.min(depCoords[0], arrCoords[0]), Math.min(depCoords[1], arrCoords[1])],
        [Math.max(depCoords[0], arrCoords[0]), Math.max(depCoords[1], arrCoords[1])]
      ]
      
      this.map.fitBounds(bounds, { padding: 140, duration: 600, maxZoom: 13 })
      
      console.log(`✨ Trajet sélectionné: ${trip.depName} → ${trip.arrName}`)
    }
  },
  computed: {
    selectedTrip() {
      if (this.selectedTripIndex < 0 || this.selectedTripIndex >= this.displayedTrips.length) {
        return null
      }
      return this.displayedTrips[this.selectedTripIndex]
    }
  },
  beforeUnmount() {
    if (this.map) {
      this.map.remove()
    }
  }
}
</script>

<style scoped>
.velov-container {
  position: relative;
  width: 100%;
  height: 100vh;
  background: #000;
}

.map-canvas {
  width: 100%;
  height: 100%;
}

.map-title {
  position: absolute;
  top: 16px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(0, 0, 0, 0.9);
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 20px;
  font-weight: 800;
  color: #22C55E;
  box-shadow: 0 2px 8px rgba(0,0,0,0.3);
  z-index: 1;
}

.stats-sidebar {
  position: absolute;
  bottom: 20px;
  left: 20px;
  background: rgba(0, 0, 0, 0.9);
  border: 1px solid rgba(34, 197, 94, 0.4);
  padding: 10px 12px;
  border-radius: 8px;
  font-size: 11px;
  color: #fff;
  z-index: 10;
  max-width: 220px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.5);
}

.stats-sidebar h2 {
  margin: 0 0 12px 0;
  font-size: 13px;
  color: #22C55E;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.stat-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 5px;
  padding: 3px 0;
  border-bottom: 1px solid rgba(34, 197, 94, 0.2);
}

.stat-item:last-child {
  border-bottom: none;
  margin-bottom: 0;
}

.stat-label {
  font-weight: 500;
  color: #ccc;
}

.stat-value {
  font-weight: 700;
  color: #22C55E;
  text-align: right;
  min-width: 62px;
}

.sidebar-divider {
  border: none;
  border-top: 1px solid rgba(34, 197, 94, 0.3);
  margin: 12px 0;
}

.map-controls {
  margin: 8px 0;
  font-size: 11px;
}

.map-controls label {
  display: flex;
  align-items: center;
  color: #22C55E;
  cursor: pointer;
  font-weight: 600;
  gap: 6px;
}

.map-controls input[type="checkbox"] {
  width: 14px;
  height: 14px;
  cursor: pointer;
  accent-color: #22C55E;
}

.trajet-selector {
  margin: 8px 0;
}

.trajet-selector label {
  display: block;
  font-size: 10px;
  font-weight: 600;
  color: #22C55E;
  margin-bottom: 6px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.trip-select {
  width: 100%;
  padding: 5px;
  background: rgba(34, 197, 94, 0.1);
  border: 1px solid rgba(34, 197, 94, 0.5);
  border-radius: 4px;
  color: #fff;
  font-size: 10px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.trip-select:hover {
  border-color: #22C55E;
  background: rgba(34, 197, 94, 0.15);
}

.trip-select:focus {
  outline: none;
  border-color: #22C55E;
  background: rgba(34, 197, 94, 0.2);
}

.trip-select option {
  background: #1a1a1a;
  color: #fff;
}

.trip-details {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid rgba(34, 197, 94, 0.3);
  max-height: 280px;
  overflow-y: auto;
}

.detail-section {
  margin-bottom: 8px;
}

.detail-section h3 {
  margin: 8px 0 6px 0;
  font-size: 11px;
  font-weight: 700;
  color: #22C55E;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  font-size: 9.5px;
  padding: 2px 0;
  border-bottom: 1px solid rgba(34, 197, 94, 0.1);
}

.detail-row:last-child {
  border-bottom: none;
}

.detail-row .label {
  font-weight: 600;
  color: #aaa;
  min-width: 58px;
}

.detail-row .value {
  font-weight: 600;
  color: #22C55E;
  text-align: right;
  flex: 1;
}

.detail-row .value.small {
  font-size: 8.5px;
  opacity: 0.9;
}

.detail-row .value.mono {
  font-family: 'Courier New', monospace;
  font-size: 9px;
  letter-spacing: -0.5px;
  word-break: break-all;
}

.back-button {
  position: absolute;
  top: 16px;
  left: 16px;
  background: #000;
  color: #22C55E;
  border: 1px solid #22C55E;
  padding: 8px 16px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.25);
  z-index: 10;
  transition: all 0.3s ease;
}

.back-button:hover {
  background: #0b0b0b;
  box-shadow: 0 4px 12px rgba(0,0,0,0.3);
  transform: translateY(-2px);
}

@media (max-width: 768px) {
  .stats-sidebar {
    max-width: 100%;
    width: calc(100% - 40px);
    left: 20px;
    right: 20px;
    bottom: 20px;
  }
  
  .map-title {
    font-size: 16px;
    padding: 10px 16px;
    left: 50%;
    top: 56px;
    transform: translateX(-50%);
  }
  
  .back-button {
    padding: 8px 16px;
    font-size: 12px;
  }
}
</style>
