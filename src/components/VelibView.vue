<template>
  
  <div class="velib-container">
    <button class="back-button" @click="$emit('back')" title="Retour à l'accueil">← Accueil</button>
    <div id="velib-map" class="map-canvas"></div>
    <div class="map-title">Paris en Vélib'</div>
    <div class="projection-info">
      Mes trajets Vélib' à Paris
      <div v-if="stats">
        <strong>{{ stats.countFeatures }}</strong> segments sur {{ stats.countTrips }} trajets — {{ stats.kmTotal }} km
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
      stats: { countTrips: 0, countFeatures: 0, kmTotal: 0 }
    }
  },
  mounted() {
    this.loadTrips()
  },
  methods: {
    resolveStation(id) {
      if (!id) return null
      const sId = String(id)
      // Tentative 1: correspondance directe
      if (this.stations[sId]) return this.stations[sId]
      // Tentative 2: essayer versions raccourcies (certains IDs longs contiennent le stationcode en suffixe)
      const candidates = [
        sId.slice(-6), sId.slice(-5), sId.slice(-4)
      ]
      for (const c of candidates) {
        if (c && this.stations[c]) return this.stations[c]
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
        this.initMap()
      }
    },
    async loadStations() {
      try {
        // 0) Fichier local (si présent dans /public)
        let stationsLocal = {}
        try {
          const respLocal = await fetch('/velib-emplacement-des-stations.json', { cache: 'no-store' })
          if (respLocal.ok) {
            const dataLocal = await respLocal.json()
            // Accepte soit une map {id: {name, coords}}, soit un array [{id, lon, lat, name}]
            if (Array.isArray(dataLocal)) {
              dataLocal.forEach(s => {
                const id = s.id || s.station_id || s.code
                const lon = s.lon ?? s.coord?.lon
                const lat = s.lat ?? s.coord?.lat
                if (id && lon != null && lat != null) {
                  stationsLocal[String(id)] = { name: s.name || 'Station', coords: [lon, lat] }
                }
              })
            } else {
              stationsLocal = dataLocal || {}
            }
          }
        } catch {}

        // 1) stationcode -> coords (OpenData proxy)
        let stations1 = {}
        try {
          const resp1 = await fetch('/api/velib-stations')
          if (resp1.ok) {
            const data1 = await resp1.json()
            stations1 = data1?.stations || {}
          }
        } catch {}

        // 2) station_id -> coords (GBFS proxy)
        let stations2 = {}
        try {
          const resp2 = await fetch('/api/velib-gbfs')
          if (resp2.ok) {
            const data2 = await resp2.json()
            stations2 = data2?.stations || {}
          }
        } catch {}

        // Fusion des trois sources
        this.stations = { ...stations1, ...stations2, ...stationsLocal }
      } catch (error) {
        console.error('Erreur chargement stations (proxy):', error)
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
      })
    },
    displayTrips() {
      if (!this.trips.length) {
        this.stats = { countTrips: 0, countFeatures: 0, kmTotal: 0 }
        return
      }

      const totalDistance = this.trips.reduce((sum, t) => 
        sum + (parseFloat(t.parameter3?.DISTANCE) || 0), 0
      )
      const totalCO2 = this.trips.reduce((sum, t) => 
        sum + (parseFloat(t.parameter3?.SAVED_CARBON_DIOXIDE) || 0), 0
      )
      
      // Crée les lignes de trajets
      const features = []
      let matchCount = 0
      const pointFeatures = []
      this.trips.forEach(trip => {
        const depId = trip.parameter3?.departureStationId
        const arrId = trip.parameter3?.arrivalStationId
        const depStation = this.resolveStation(depId)
        const arrStation = this.resolveStation(arrId)
        
        if (depStation && arrStation && depId !== arrId) {
          matchCount++
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
          // Fallback: tracer des points si une des stations n'est pas résolue
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
            'line-opacity': 0.6
          }
        })
        
        console.log(`${features.length} trajets affichés | ${(totalDistance/1000).toFixed(1)} km | ${totalCO2.toFixed(0)}g CO2 économisés`)
      } else {
        console.warn('Aucun segment affiché: probable mismatch entre IDs de stations et dataset temps réel.')
      }

      // Ajout des points en fallback pour visualiser les stations reconnues
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
            'circle-radius': 4,
            'circle-color': [
              'match', ['get', 'type'],
              'depart', '#00FF99',
              'arrivee', '#FFD166',
              '#00D9FF'
            ],
            'circle-opacity': 0.85,
            'circle-stroke-color': '#000',
            'circle-stroke-width': 1
          }
        })
        console.log(`Points fallback affichés: ${pointFeatures.length}`)
      }

      // Fit bounds sur l'ensemble des coordonnés visibles (lignes + points)
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
        const minLon = Math.min(...lons)
        const maxLon = Math.max(...lons)
        const minLat = Math.min(...lats)
        const maxLat = Math.max(...lats)
        const bounds = [[minLon, minLat], [maxLon, maxLat]]
        this.map.fitBounds(bounds, { padding: 60, maxZoom: 14, duration: 800 })
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
  background: rgba(0, 0, 0, 0.75);
  padding: 8px 16px;
  border-radius: 6px;
  font-size: 13px;
  color: #fff;
  z-index: 1;
}

.back-button {
  position: absolute;
  top: 20px;
  right: 20px;
  background: rgba(255, 255, 255, 0.95);
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
  z-index: 10;
  transition: all 0.3s ease;
}

.back-button:hover {
  background: #fff;
  box-shadow: 0 4px 12px rgba(0,0,0,0.2);
  transform: translateY(-2px);
}
</style>
