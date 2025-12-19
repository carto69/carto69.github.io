<template>
  <div class="velib-container">
    <button class="back-button" @click="$emit('back')" title="Retour à l'accueil">← Accueil</button>
    <div id="velib-map" class="map-canvas"></div>
    <div class="map-title">le 75 en vélib</div>
    
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
      
      <!-- Options de la carte + Sélecteur de trajet -->
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
        <div class="trajet-selector" style="margin: 0;">
          <label style="margin-right: 0.5em;">Analyser un trajet:</label>
          <select v-model="selectedTripIndex" @change="onTripSelected" class="trip-select">
            <option :value="-1">-- Sélectionner --</option>
            <option v-for="(trip, idx) in displayedTrips" :key="idx" :value="idx">
              {{ trip.idx + 1 }}. {{ trip.depName }} → {{ trip.arrName }} ({{ trip.distance }}m)
            </option>
          </select>
        </div>
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
  name: 'VelibView',
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
            if (this.map.getLayer('velib-heatmap')) {
              this.map.setLayoutProperty('velib-heatmap', 'visibility', 'none')
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
          if (!this.map.getSource('velib-heatmap')) {
            this.map.addSource('velib-heatmap', {
              type: 'geojson',
              data: { type: 'FeatureCollection', features: heatFeatures }
            })
            this.map.addLayer({
              id: 'velib-heatmap',
              type: 'heatmap',
              source: 'velib-heatmap',
              maxzoom: 15,
              paint: {
                'heatmap-weight': 1,
                'heatmap-intensity': 1.2,
                'heatmap-color': [
                  'interpolate', ['linear'], ['heatmap-density'],
                  0, 'rgba(0,0,0,0)',
                  0.2, '#00D9FF',
                  0.4, '#0EA5E9',
                  0.6, '#0369A1',
                  1, '#F59E42'
                ],
                'heatmap-radius': 32,
                'heatmap-opacity': 0.8
              }
            })
          } else {
            this.map.getSource('velib-heatmap').setData({ type: 'FeatureCollection', features: heatFeatures })
            this.map.setLayoutProperty('velib-heatmap', 'visibility', 'visible')
          }
        },
    resolveStation(id) {
      if (!id) return null
      const sId = String(id).trim()
      
      // Correspondances manuelles pour les IDs non standards
      const manualMapping = {
        '5501': '516395829',          // Quai Des Célestins - Henri Iv (id court)
        '20431005501': '516395829',   // Quai Des Célestins - Henri Iv (id long)
        '20531346153': '218903767'    // René Boulanger - Lancry
      }
      
      const mappedId = manualMapping[sId] || sId
      
      // UNIQUEMENT correspondance exacte - pas de logique de matching partiel
      if (this.stations[mappedId]) {
        return this.stations[mappedId]
      }
      
      // Debug pour les stations non trouvées
      if (!this.stations[mappedId]) {
        console.warn(`✗ Station ${sId} (mappé: ${mappedId}) NON TROUVÉE dans les ${Object.keys(this.stations).length} stations`)
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
                  const lon = coords[0]
                  const lat = coords[1]
                  
                  // 🔍 Vérifier si c'est Lambert 93 (grande valeurs ~680000-850000) ou lat/lon (~2.3 et 48.8)
                  let finalCoords = [lon, lat]
                  if (lon > 100 && lat > 100) {
                    // Probablement Lambert 93 - convertir vers lat/lon
                    console.warn(`⚠️ Coords Lambert 93 détectées: [${lon}, ${lat}] pour ${s.name}`)
                    // Conversion Lambert 93 → WGS84
                    const epsg2154to4326 = (lambertE, lambertN) => {
                      // Approximation simple pour Paris région (TRÈS GROSSIÈRE)
                      const n = 0.7256077650532472
                      const c = 11603796.987734
                      const xs = 700000
                      const ys = 12655900
                      const e = 0.08248325676
                      
                      const rho = Math.sqrt(Math.pow(lambertE - xs, 2) + Math.pow(lambertN - ys, 2))
                      const gamma = Math.atan((lambertE - xs) / (ys - lambertN))
                      const lon = gamma / n + 2.337229166
                      const lat = 2 * Math.atan(Math.pow(c / rho, 1 / n) * Math.exp(-e / 2 * Math.log((1 + e * Math.sin(lon)) / (1 - e * Math.sin(lon))))) - Math.PI / 2
                      
                      return [lon * 180 / Math.PI, lat * 180 / Math.PI]
                    }
                    // finalCoords = epsg2154to4326(lon, lat)
                  }
                  
                  stationsComplete[id] = { 
                    name: s.name || `Station ${id}`, 
                    coords: finalCoords
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

        // Fusion: priorité à la source complète (ne pas écraser avec local)
        this.stations = { ...stationsLocal, ...stationsComplete }
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
        center: [2.3522, 48.8566],
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
      this.displayedTrips = []
      
      console.group('🗺️ VELIB MAP DEBUG')
      console.log(`Nombre total de trajets: ${this.trips.length}`)
      console.log(`Nombre total de stations disponibles: ${Object.keys(this.stations).length}`)
      
      this.trips.forEach((trip, idx) => {
        const depId = trip.parameter3?.departureStationId
        const arrId = trip.parameter3?.arrivalStationId
        
        if (idx < 3) {
          console.log(`\n📍 Trajet ${idx + 1}: Départ=${depId}, Arrivée=${arrId}`)
        }
        
        const depStation = this.resolveStation(depId)
        const arrStation = this.resolveStation(arrId)
        
        if (idx < 3) {
          console.log(`  Départ résolue: ${depStation ? depStation.name + ' ' + depStation.coords : 'NON TROUVÉE'}`)
          console.log(`  Arrivée résolue: ${arrStation ? arrStation.name + ' ' + arrStation.coords : 'NON TROUVÉE'}`)
        }
        
        // IMPORTANT: ne créer le segment QUE si les deux stations sont trouvées
        if (depStation && arrStation && depId !== arrId) {
          const displayTrip = {
            idx: idx,
            depId: String(depId),
            arrId: String(arrId),
            depName: depStation.name,
            arrName: arrStation.name,
            depCoords: depStation.coords.join(', '),
            arrCoords: arrStation.coords.join(', '),
            distance: parseFloat(trip.parameter3.DISTANCE),
            speed: trip.parameter3.AVERAGE_SPEED,
            date: trip.startDate,
            co2: trip.parameter3.SAVED_CARBON_DIOXIDE
          }
          
          this.displayedTrips.push(displayTrip)
          
          features.push({
            type: 'Feature',
            geometry: {
              type: 'LineString',
              coordinates: [depStation.coords, arrStation.coords]
            },
            properties: {
              distance: trip.parameter3.DISTANCE,
              date: trip.startDate,
              speed: trip.parameter3.AVERAGE_SPEED,
              depName: depStation.name,
              arrName: arrStation.name
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
          },
          layout: {
            'visibility': this.showHotspot ? 'none' : 'visible'
          }
        })

        // Masquer la heatmap si elle existe
        if (this.map.getLayer('velib-heatmap')) {
          this.map.setLayoutProperty('velib-heatmap', 'visibility', 'none')
        }

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
    },
    displayStations() {
      if (!this.map || !this.showStations) return
      
      const stationFeatures = []
      const addedCoords = new Set()
      
      // Créer des points pour chaque station unique utilisée
      this.displayedTrips.forEach(trip => {
        const depKey = trip.depCoords
        const arrKey = trip.arrCoords
        
        if (!addedCoords.has(depKey)) {
          const [lon, lat] = trip.depCoords.split(', ').map(Number)
          stationFeatures.push({
            type: 'Feature',
            geometry: { type: 'Point', coordinates: [lon, lat] },
            properties: { name: trip.depName, id: trip.depId }
          })
          addedCoords.add(depKey)
        }
        
        if (!addedCoords.has(arrKey)) {
          const [lon, lat] = trip.arrCoords.split(', ').map(Number)
          stationFeatures.push({
            type: 'Feature',
            geometry: { type: 'Point', coordinates: [lon, lat] },
            properties: { name: trip.arrName, id: trip.arrId }
          })
          addedCoords.add(arrKey)
        }
      })
      
      if (stationFeatures.length === 0) return
      
      // Ajouter la source et la couche
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
            'circle-color': '#00D9FF',
            'circle-opacity': 0.8,
            'circle-stroke-width': 2,
            'circle-stroke-color': '#fff'
          }
        })
        
        // Ajouter les popups au survol
        const popup = new mapboxgl.Popup({ closeButton: false, closeOnClick: false })
        
        this.map.on('mouseenter', 'stations-layer', (e) => {
          this.map.getCanvas().style.cursor = 'pointer'
          const props = e.features[0].properties
          popup.setLngLat(e.lngLat)
            .setHTML(`<div style="color: #00D9FF; font-size: 12px; font-weight: 600;">${props.name}</div>`)
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
        // Afficher les stations
        if (this.map.getLayer('stations-layer')) {
          this.map.setLayoutProperty('stations-layer', 'visibility', 'visible')
        } else {
          this.displayStations()
        }
      } else {
        // Masquer les stations
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
      
      // Curseur au survol des trajets
      this.map.on('mouseenter', 'trips-layer', () => {
        this.map.getCanvas().style.cursor = 'pointer'
      })
      this.map.on('mouseleave', 'trips-layer', () => {
        this.map.getCanvas().style.cursor = ''
      })
    },
    onTripSelected() {
      if (!this.map || this.selectedTripIndex < 0) {
        // Réinitialiser le surlignage
        if (this.map && this.map.getLayer('trips-highlight')) {
          this.map.setPaintProperty('trips-highlight', 'line-opacity', 0)
        }
        return
      }
      
      const trip = this.selectedTrip
      if (!trip) return
      
      // Créer une couche de surlignage avec juste ce trajet
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
      
      // Vérifier si la couche existe déjà
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
        // Mettre à jour la source
        this.map.getSource('trips-highlight').setData(highlightFeature)
        this.map.setPaintProperty('trips-highlight', 'line-opacity', 0.9)
      }
      
      // Zoomer sur le trajet
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
  top: 16px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(0, 0, 0, 0.9);
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 20px;
  font-weight: 800;
  color: #00D9FF;
  box-shadow: 0 2px 8px rgba(0,0,0,0.3);
  z-index: 1;
}

.stats-sidebar {
  position: absolute;
  bottom: 20px;
  left: 20px;
  background: rgba(0, 0, 0, 0.9);
  border: 1px solid rgba(0, 217, 255, 0.4);
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
  color: #00D9FF;
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
  min-width: 62px;
}

.sidebar-divider {
  border: none;
  border-top: 1px solid rgba(0, 217, 255, 0.3);
  margin: 12px 0;
}

.map-controls {
  margin: 8px 0;
  font-size: 11px;
}

.map-controls label {
  display: flex;
  align-items: center;
  color: #00D9FF;
  cursor: pointer;
  font-weight: 600;
  gap: 6px;
}

.map-controls input[type="checkbox"] {
  width: 14px;
  height: 14px;
  cursor: pointer;
  accent-color: #00D9FF;
}

.trajet-selector {
  margin: 8px 0;
}

.trajet-selector label {
  display: block;
  font-size: 10px;
  font-weight: 600;
  color: #00D9FF;
  margin-bottom: 6px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.trip-select {
  width: 100%;
  padding: 5px;
  background: rgba(0, 217, 255, 0.1);
  border: 1px solid rgba(0, 217, 255, 0.5);
  border-radius: 4px;
  color: #fff;
  font-size: 10px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.trip-select:hover {
  border-color: #00D9FF;
  background: rgba(0, 217, 255, 0.15);
}

.trip-select:focus {
  outline: none;
  border-color: #00D9FF;
  background: rgba(0, 217, 255, 0.2);
}

.trip-select option {
  background: #1a1a1a;
  color: #fff;
}

.trip-details {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid rgba(0, 217, 255, 0.3);
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
  color: #00D9FF;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  font-size: 9.5px;
  padding: 2px 0;
  border-bottom: 1px solid rgba(0, 217, 255, 0.1);
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
  color: #00D9FF;
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
  color: #00D9FF;
  border: 1px solid #00D9FF;
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
