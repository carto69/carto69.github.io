<template>
  <div class="velib-container">
    <button class="back-button" @click="$emit('back')" title="Retour à l'accueil">← Accueil</button>
    <div id="velib-map" class="map-canvas"></div>
    <div class="map-title">Paris en Vélib'</div>
    <div class="projection-info">
      Mes trajets Vélib' à Paris
      <div v-if="stats">
        <strong>{{ stats.countFeatures }}</strong> segments sur <strong>{{ stats.countTrips }}</strong> trajets — <strong>{{ stats.kmTotal }} km</strong>
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
      stats: { countTrips: 0, countFeatures: 0, kmTotal: 0 },
      loading: true,
      error: null
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
      
      // Tentative 2: versions raccourcies (cas où l'ID contient du padding)
      const attempts = [sId, sId.slice(-8), sId.slice(-6), sId.slice(-5), sId.slice(-4), sId.slice(0, 4)]
      for (const attempt of attempts) {
        if (attempt && this.stations[attempt]) {
          return this.stations[attempt]
        }
      }
      
      return null
    },
    async loadTrips() {
      try {
        const response = await fetch('/velib-trips.json')
        const data = await response.json()
        this.trips = data.walletOperations || []
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
        // Sources de stations (essayées dans l'ordre)
        let stationsLocal = {}
        
        // 1) Fichier local /public/velib-emplacement-des-stations.json
        try {
          const respLocal = await fetch('/velib-emplacement-des-stations.json', { cache: 'no-store' })
          if (respLocal.ok) {
            const dataLocal = await respLocal.json()
            if (Array.isArray(dataLocal)) {
              dataLocal.forEach(s => {
                const id = String(s.id || s.station_id || s.code || '')
                const lon = s.lon ?? s.coord?.lon
                const lat = s.lat ?? s.coord?.lat
                if (id && lon != null && lat != null) {
                  stationsLocal[id] = { name: s.name || 'Station', coords: [lon, lat] }
                }
              })
            } else {
              stationsLocal = dataLocal || {}
            }
            console.log('✓ Stations locales chargées:', Object.keys(stationsLocal).length)
          }
        } catch (e) {
          console.warn('Fichier local indisponible:', e.message)
        }

        // 2) OpenData proxy (stationcode)
        let stations1 = {}
        try {
          const resp1 = await fetch('/api/velib-stations', { signal: AbortSignal.timeout(5000) })
          if (resp1.ok) {
            const data1 = await resp1.json()
            stations1 = data1?.stations || {}
            console.log('✓ OpenData proxy:', Object.keys(stations1).length, 'stations')
          }
        } catch (e) {
          console.warn('OpenData proxy inaccessible:', e.message)
        }

        // 3) GBFS proxy (station_id)
        let stations2 = {}
        try {
          const resp2 = await fetch('/api/velib-gbfs', { signal: AbortSignal.timeout(5000) })
          if (resp2.ok) {
            const data2 = await resp2.json()
            stations2 = data2?.stations || {}
            console.log('✓ GBFS proxy:', Object.keys(stations2).length, 'stations')
          }
        } catch (e) {
          console.warn('GBFS proxy inaccessible:', e.message)
        }

        // Fusion: priorité au local, puis opendata, puis gbfs
        this.stations = { ...stations1, ...stations2, ...stationsLocal }
        const count = Object.keys(this.stations).length
        if (count === 0) {
          this.error = 'Aucune donnée de stations disponible. Veuillez vérifier /public/velib-emplacement-des-stations.json ou les APIs.'
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
        this.stats = { countTrips: 0, countFeatures: 0, kmTotal: 0 }
        console.warn('Aucun trajet à afficher')
        return
      }

      const totalDistance = this.trips.reduce((sum, t) => 
        sum + (parseFloat(t.parameter3?.DISTANCE) || 0), 0
      )
      
      // Collecte des IDs et stats de résolution
      const allIds = []
      const resolved = {}
      const unresolved = {}
      
      this.trips.forEach(trip => {
        const depId = String(trip.parameter3?.departureStationId || '')
        const arrId = String(trip.parameter3?.arrivalStationId || '')
        allIds.push(depId, arrId)
        
        const depStation = this.resolveStation(depId)
        const arrStation = this.resolveStation(arrId)
        
        if (depStation) resolved[depId] = true
        else if (depId) unresolved[depId] = true
        
        if (arrStation) resolved[arrId] = true
        else if (arrId) unresolved[arrId] = true
      })
      
      console.log(`Résolution des stations: ${Object.keys(resolved).length} résolues / ${Object.keys(unresolved).length} non-résolues`)
      if (Object.keys(unresolved).length > 0) {
        console.log('IDs non-résolues (premiers 10):', Object.keys(unresolved).slice(0, 10))
      }

      // Crée les lignes de trajets
      const features = []
      const pointFeatures = []
      
      this.trips.forEach(trip => {
        const depId = trip.parameter3?.departureStationId
        const arrId = trip.parameter3?.arrivalStationId
        const depStation = this.resolveStation(depId)
        const arrStation = this.resolveStation(arrId)
        
        if (depStation && arrStation && depId !== arrId) {
          // Trajet complet: ligne
          features.push({
            type: 'Feature',
            geometry: {
              type: 'LineString',
              coordinates: [depStation.coords, arrStation.coords]
            },
            properties: {
              distance: trip.parameter3.DISTANCE,
              date: trip.startDate
            }
          })
        } else {
          // Fallback: afficher les points individuels
          if (depStation) {
            pointFeatures.push({
              type: 'Feature',
              geometry: { type: 'Point', coordinates: depStation.coords },
              properties: { type: 'depart', date: trip.startDate }
            })
          }
          if (arrStation) {
            pointFeatures.push({
              type: 'Feature',
              geometry: { type: 'Point', coordinates: arrStation.coords },
              properties: { type: 'arrivee', date: trip.startDate }
            })
          }
        }
      })

      this.stats = {
        countTrips: this.trips.length,
        countFeatures: features.length,
        kmTotal: +(totalDistance / 1000).toFixed(1)
      }

      console.log(`📊 Stats: ${features.length} segments | ${this.stats.kmTotal} km | ${this.trips.length} trajets`)

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
            'line-width': 2,
            'line-opacity': 0.7
          }
        })
        
        console.log(`✓ ${features.length} trajets affichés sur la carte`)
      } else {
        console.warn('⚠️ Aucun segment affiché: probable mismatch IDs')
      }

      // Affiche les points fallback
      if (pointFeatures.length > 0) {
        this.map.addSource('trips-points', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features: pointFeatures }
        })
        this.map.addLayer({
          id: 'trips-points-layer',
          type: 'circle',
          source: 'trips-points',
          paint: {
            'circle-radius': 5,
            'circle-color': [
              'match', ['get', 'type'],
              'depart', '#00FF99',
              'arrivee', '#FFD166',
              '#00D9FF'
            ],
            'circle-opacity': 0.8,
            'circle-stroke-color': '#000',
            'circle-stroke-width': 1
          }
        })
        console.log(`✓ ${pointFeatures.length} points fallback affichés`)
      }

      // Fit bounds
      const coords = []
      features.forEach(f => {
        f.geometry.coordinates.forEach(c => coords.push(c))
      })
      pointFeatures.forEach(p => {
        coords.push(p.geometry.coordinates)
      })
      
      if (coords.length > 0) {
        const lons = coords.map(c => c[0])
        const lats = coords.map(c => c[1])
        const bounds = [[Math.min(...lons), Math.min(...lats)], [Math.max(...lons), Math.max(...lats)]]
        this.map.fitBounds(bounds, { padding: 60, maxZoom: 14, duration: 800 })
      } else {
        this.map.setCenter([2.35, 48.86])
        this.map.setZoom(11.5)
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

.projection-info {
  position: absolute;
  bottom: 30px;
  left: 20px;
  background: rgba(0, 0, 0, 0.85);
  padding: 12px 16px;
  border-radius: 6px;
  font-size: 13px;
  color: #fff;
  z-index: 1;
  line-height: 1.5;
}

.projection-info strong {
  color: #00D9FF;
  font-weight: 600;
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
</style>
