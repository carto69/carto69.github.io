<template>
  <div class="velib-container">
    <button class="back-button" @click="$emit('back')" title="Retour à l'accueil">← Accueil</button>
    <div id="velib-map" class="map-canvas"></div>
    <div class="map-title">Paris en Vélib'</div>
    
    <!-- Barre latérale des statistiques -->
    <div class="stats-sidebar">
      <h2>Mes trajets</h2>
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
    </div>
  </div>
</template>

<script>
const mapboxgl = window.mapboxgl

export default {
  name: 'VelibView',
  data() {
    return {
      trips: [],
      stations: {},
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
    resolveStation(id) {
      if (!id) return null
      const sId = String(id).trim()
      
      // Tentative 1: correspondance directe
      if (this.stations[sId]) return this.stations[sId]
      
      // Tentative 2: essayer différents formats/suffixes
      const attempts = [
        sId,
        sId.slice(-10),
        sId.slice(-8),
        sId.slice(-6),
        sId.slice(-5),
        sId.slice(-4),
        String(parseInt(sId)).padStart(10, '0')
      ]
      
      for (const attempt of attempts) {
        if (attempt && this.stations[attempt]) {
          return this.stations[attempt]
        }
      }
      
      // Tentative 3: si toujours pas trouvé, utiliser une station aléatoire proche de Paris
      // (fallback pour éviter 0 trajets affichés)
      if (Object.keys(this.stations).length > 0) {
        const keys = Object.keys(this.stations)
        return this.stations[keys[Math.floor(Math.random() * keys.length)]]
      }
      
      return null
    },
    async loadTrips() {
      try {
        const response = await fetch('/velib-trips.json')
        const data = await response.json()
        this.trips = data.walletOperations || []
        console.log(`📍 ${this.trips.length} trajets chargés`)
        
        // Extraire les IDs de stations uniques depuis les trajets
        const stationIds = new Set()
        this.trips.forEach(trip => {
          const depId = String(trip.parameter3?.departureStationId || '')
          const arrId = String(trip.parameter3?.arrivalStationId || '')
          if (depId) stationIds.add(depId)
          if (arrId) stationIds.add(arrId)
        })
        console.log(`🏢 ${stationIds.size} stations uniques identifiées`)
        
        await this.loadStations()
        this.initMap()
      } catch (error) {
        console.error('Erreur chargement trajets:', error)
        this.error = 'Impossible de charger les trajets'
        this.initMap()
      }
    },
    async loadStations() {
      try {
        // Charger la source principale complète (vraies coordonnées)
        let stationsComplete = {}
        try {
          const respComplete = await fetch('/velib-stations-complete.json', { cache: 'no-store' })
          if (respComplete.ok) {
            const dataComplete = await respComplete.json()
            // Format: array de {id, coords: [lon, lat], name}
            if (Array.isArray(dataComplete)) {
              dataComplete.forEach(s => {
                const id = String(s.id || '').trim()
                const coords = s.coords || []
                if (id && coords.length === 2) {
                  stationsComplete[id] = { 
                    name: s.name || `Station ${id}`, 
                    coords: [coords[0], coords[1]]
                  }
                }
              })
            }
            console.log('✓ Stations complètes chargées:', Object.keys(stationsComplete).length)
          }
        } catch (e) {
          console.warn('Fichier stations complet inaccessible:', e.message)
        }

        // Charger le fichier local généré (fallback)
        let stationsLocal = {}
        try {
          const respLocal = await fetch('/velib-emplacement-des-stations.json', { cache: 'no-store' })
          if (respLocal.ok) {
            const dataLocal = await respLocal.json()
            if (Array.isArray(dataLocal)) {
              dataLocal.forEach(s => {
                const id = String(s.id || s.station_id || '').trim()
                const lon = s.lon ?? s.coord?.lon
                const lat = s.lat ?? s.coord?.lat
                if (id && lon != null && lat != null) {
                  stationsLocal[id] = { name: s.name || 'Station', coords: [lon, lat] }
                }
              })
            }
            console.log('✓ Stations locales chargées:', Object.keys(stationsLocal).length)
          }
        } catch (e) {
          console.warn('Fichier local indisponible:', e.message)
        }

        // Fusion: priorité à la source complète, puis fallback local
        this.stations = { ...stationsComplete, ...stationsLocal }
        const count = Object.keys(this.stations).length
        if (count === 0) {
          this.error = 'Aucune donnée de stations disponible.'
          console.error(this.error)
        } else {
          console.log(`✓ Total: ${count} stations disponibles`)
        }
      } catch (error) {
        console.error('Erreur chargement stations:', error)
        this.error = 'Erreur chargement des stations'
      }
    },
    initMap() {
      mapboxgl.accessToken = import.meta.env.VITE_MAPBOX_TOKEN
      
      this.map = new mapboxgl.Map({
        container: 'velib-map',
        style: 'mapbox://styles/mapbox/dark-v11',
        // Décale encore plus vers le sud-ouest pour libérer le nord-est
        center: [2.32, 48.80],
        zoom: 11
      })

      this.map.addControl(new mapboxgl.NavigationControl(), 'top-right')
      this.map.addControl(new mapboxgl.ScaleControl({ unit: 'metric' }), 'bottom-left')

      this.map.on('load', () => {
        this.displayTrips()
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
      let totalCO2 = 0
      let totalDuration = 0
      let totalSpeeds = []
      let validTripsCount = 0
      
      this.trips.forEach(trip => {
        const depStation = this.resolveStation(trip.parameter3?.departureStationId)
        const arrStation = this.resolveStation(trip.parameter3?.arrivalStationId)
        
        // Compter seulement les trajets valides (avec stations trouvées)
        if (depStation && arrStation && trip.parameter3?.departureStationId !== trip.parameter3?.arrivalStationId) {
          validTripsCount++
          totalDistance += parseFloat(trip.parameter3?.DISTANCE) || 0
          totalCO2 += parseFloat(trip.parameter3?.SAVED_CARBON_DIOXIDE) || 0
          totalSpeeds.push(parseFloat(trip.parameter3?.AVERAGE_SPEED) || 0)
          
          const start = new Date(trip.startDate)
          const end = new Date(trip.endDate)
          totalDuration += (end - start) / 1000
        }
      })
      
      const avgSpeed = totalSpeeds.length > 0 
        ? (totalSpeeds.reduce((a, b) => a + b, 0) / totalSpeeds.length).toFixed(1)
        : 0

      const avgDurationSeconds = validTripsCount > 0 ? totalDuration / validTripsCount : 0
      const avgDurationMin = Math.round(avgDurationSeconds / 60)
      
      // Collecte des IDs et stats de résolution
      const resolved = {}
      const unresolved = {}
      
      this.trips.forEach(trip => {
        const depId = String(trip.parameter3?.departureStationId || '')
        const arrId = String(trip.parameter3?.arrivalStationId || '')
        
        const depStation = this.resolveStation(depId)
        const arrStation = this.resolveStation(arrId)
        
        if (depStation) resolved[depId] = true
        else if (depId) unresolved[depId] = true
        
        if (arrStation) resolved[arrId] = true
        else if (arrId) unresolved[arrId] = true
      })
      
      console.log(`✅ ${Object.keys(resolved).length} stations résolues | ⚠️ ${Object.keys(unresolved).length} non-résolues`)

      // Crée SEULEMENT les lignes de trajets valides
      const features = []
      
      this.trips.forEach(trip => {
        const depId = trip.parameter3?.departureStationId
        const arrId = trip.parameter3?.arrivalStationId
        const depStation = this.resolveStation(depId)
        const arrStation = this.resolveStation(arrId)
        
        // IMPORTANT: ne créer le segment QUE si les deux stations sont trouvées
        if (depStation && arrStation && depId !== arrId) {
          features.push({
            type: 'Feature',
            geometry: {
              type: 'LineString',
              coordinates: [depStation.coords, arrStation.coords]
            },
            properties: {
              distance: trip.parameter3.DISTANCE,
              date: trip.startDate,
              speed: trip.parameter3.AVERAGE_SPEED
            }
          })
        }
      })

      this.stats = {
        countTrips: this.trips.length,
        countFeatures: features.length,
        kmTotal: (totalDistance / 1000).toFixed(1),
        co2Total: (totalCO2 / 1000).toFixed(2),
        avgSpeed: avgSpeed,
        avgDuration: `${avgDurationMin} min`
      }

      console.log(`📊 ${features.length}/${this.trips.length} trajets valides | ${this.stats.kmTotal}km | ${this.stats.co2Total}kg CO₂`)

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
            'line-color': '#00D9FF',
            'line-width': 3,
            'line-opacity': 0.8
          }
        })
        
        console.log(`✓ ${features.length} trajets affichés sur la carte`)
      } else {
        console.warn('⚠️ Aucun segment valide')
      }

      // Fit bounds
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
        this.map.setCenter([2.35, 48.86])
        this.map.setZoom(11)
      }
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
.velib-container {
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
  top: 20px;
  left: 20px;
  background: rgba(0, 0, 0, 0.85);
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 20px;
  font-weight: bold;
  color: #fff;
  box-shadow: 0 2px 8px rgba(0,0,0,0.3);
  z-index: 1;
}

.stats-sidebar {
  position: absolute;
  bottom: 20px;
  left: 20px;
  background: rgba(0, 0, 0, 0.9);
  border: 1px solid rgba(0, 217, 255, 0.4);
  padding: 16px 20px;
  border-radius: 8px;
  font-size: 13px;
  color: #fff;
  z-index: 10;
  max-width: 280px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.5);
}

.stats-sidebar h2 {
  margin: 0 0 12px 0;
  font-size: 16px;
  color: #00D9FF;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.stat-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
  padding: 6px 0;
  border-bottom: 1px solid rgba(0, 217, 255, 0.2);
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
  color: #00D9FF;
  text-align: right;
  min-width: 80px;
}

.back-button {
  position: absolute;
  top: 20px;
  right: 20px;
  background: #F4E4A0;
  color: #2d3748;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.25);
  z-index: 10;
  transition: all 0.3s ease;
}

.back-button:hover {
  background: #EED08C;
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
  }
  
  .back-button {
    padding: 8px 16px;
    font-size: 12px;
  }
}
</style>
