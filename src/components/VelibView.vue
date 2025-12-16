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
        // Charge toutes les stations en plusieurs pages pour ne pas rater de codes
        const limit = 500
        let offset = 0
        let hasMore = true

        while (hasMore) {
          const url = `https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/velib-disponibilite-en-temps-reel/records?limit=${limit}&offset=${offset}`
          const response = await fetch(url)
          const data = await response.json()
          const results = data?.results || []

          results.forEach(station => {
            // Mapping principal: stationcode
            this.stations[station.stationcode] = {
              name: station.name,
              coords: [station.coordonnees_geo.lon, station.coordonnees_geo.lat]
            }
            // Fallbacks possibles: certains IDs de trajets peuvent référencer d'autres champs
            if (station.station_id) {
              this.stations[station.station_id] = {
                name: station.name,
                coords: [station.coordonnees_geo.lon, station.coordonnees_geo.lat]
              }
            }
          })

          hasMore = results.length === limit
          offset += limit
        }

        // Second dataset fallback: géolocalisation des stations (si différents IDs)
        try {
          const url2 = `https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/velib-stations/records?limit=${limit}`
          const response2 = await fetch(url2)
          const data2 = await response2.json()
          const results2 = data2?.results || []

          results2.forEach(s => {
            const code = s.stationcode || s.station_id || s.code || s.id
            const lon = s?.coord?.lon || s?.geo_point_2d?.lon || s?.geometry?.coordinates?.[0]
            const lat = s?.coord?.lat || s?.geo_point_2d?.lat || s?.geometry?.coordinates?.[1]
            if (code && lon != null && lat != null && !this.stations[code]) {
              this.stations[code] = { name: s?.name || s?.station_name || 'Station', coords: [lon, lat] }
            }
          })
        } catch (e2) {
          console.warn('Fallback velib-stations indisponible:', e2)
        }
      } catch (error) {
        console.error('Erreur chargement stations:', error)
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
      this.trips.forEach(trip => {
        const depId = trip.parameter3?.departureStationId
        const arrId = trip.parameter3?.arrivalStationId
        const depStation = this.stations[depId]
        const arrStation = this.stations[arrId]
        
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
