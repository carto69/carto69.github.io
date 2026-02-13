<template>
  <div class="copskill-view">
    <div class="map-wrapper">

      <div class="top-bar">
        <h1 class="map-title">Morts de la Police Française (1977-2022)</h1>
        <button class="back-btn" @click="$emit('back')">← Retour</button>
      </div>

      <div id="map" class="main-map"></div>

      <div class="domtom-container">
        <div class="domtom-grid">
          <div class="domtom-map">
            <div class="map-label">Guadeloupe</div>
            <div id="map-guadeloupe" class="map"></div>
          </div>
          <div class="domtom-map">
            <div class="map-label">Martinique</div>
            <div id="map-martinique" class="map"></div>
          </div>
          <div class="domtom-map">
            <div class="map-label">Guyane</div>
            <div id="map-guyane" class="map"></div>
          </div>
          <div class="domtom-map">
            <div class="map-label">Mayotte</div>
            <div id="map-mayotte" class="map"></div>
          </div>
          <div class="domtom-map">
            <div class="map-label">La Réunion</div>
            <div id="map-reunion" class="map"></div>
          </div>
          <div class="domtom-map">
            <div class="map-label">Nouvelle-Calédonie</div>
            <div id="map-nouvelle-caledonie" class="map"></div>
          </div>
        </div>
      </div>

      <div class="popup-info" v-if="selectedPerson">
        <div class="popup-header">
          <h3>{{ selectedPerson.prenom }} {{ selectedPerson.nom }}</h3>
          <button @click="selectedPerson = null">✕</button>
        </div>
        <div class="popup-body">
          <p><strong>Date :</strong> {{ displayValue(selectedPerson.mois) }}</p>
          <p><strong>Ville :</strong> {{ displayValue(selectedPerson.ville) }}</p>
          <p><strong>Département :</strong> {{ displayValue(selectedPerson.departement) }}</p>
          <p><strong>Genre :</strong> {{ displayGenre(selectedPerson.genre) }}</p>
          <p><strong>Âge :</strong> {{ displayAge(selectedPerson.age) }}</p>
          <p><strong>Cause officielle :</strong> {{ displayValue(selectedPerson.cause) }}</p>
          <p><strong>Lieu :</strong> {{ displayValue(selectedPerson.lieu) }}</p>
          <p><strong>Unité de police :</strong> {{ displayValue(selectedPerson.unite) }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

export default {
  name: 'CopsKillView',
  emits: ['back'],
  data() {
    return {
      map: null,
      data: [],
      selectedPerson: null,
      markers: [],
      cityCoordinates: {}
    }
  },
  async mounted() {
    document.title = 'Cops Kill - carto69'
    await this.loadCityCoordinates()
    await this.loadData()
    this.initMap()
  },
  beforeUnmount() {
    document.title = 'carto69'
    if (this.map) {
      this.map.remove()
    }
  },
  methods: {
    displayValue(val) {
      if (!val) return 'X'
      const trimmed = String(val).trim()
      return trimmed.length ? trimmed : 'X'
    },
    displayGenre(genre) {
      const g = genre ? genre.trim().toUpperCase() : ''
      if (g === 'H') return 'Homme'
      if (g === 'F') return 'Femme'
      return 'X'
    },
    displayAge(age) {
      if (!age) return 'X'
      const num = Number(age)
      return Number.isFinite(num) && num > 0 ? num : 'X'
    },
    async loadCityCoordinates() {
      try {
        const response = await fetch('/city-coordinates.json')
        this.cityCoordinates = await response.json()
      } catch (error) {
        console.error('Erreur chargement coordonnées:', error)
      }
    },
    async loadData() {
      try {
        const response = await fetch('/actions-police-fatales.csv')
        const text = await response.text()
        this.data = this.parseCSV(text)
        
        const domtomRecords = this.data.filter(p => {
          const dept = p.departement ? p.departement.trim() : ''
          return dept === 'Guadeloupe' || dept === 'Martinique' || dept === 'Guyane' || 
                 dept === 'Mayotte' || dept === 'La Réunion' || dept === 'Nouvelle-Calédonie'
        })
        console.log('DOM-TOM records found:', domtomRecords.length)
        if (domtomRecords.length > 0) {
          console.log('First DOM-TOM:', domtomRecords[0])
        }
      } catch (error) {
        console.error('Erreur chargement CSV:', error)
      }
    },
    parseCSV(text) {
      const lines = text.trim().split('\n')
      const headers = lines[0].split(',')
      const result = []

      for (let i = 1; i < lines.length; i++) {
        const obj = {}
        const row = this.parseCSVLine(lines[i])

        headers.forEach((header, index) => {
          obj[header] = row[index] || ''
        })
        result.push(obj)
      }
      return result
    },
    parseCSVLine(line) {
      const result = []
      let current = ''
      let inQuotes = false

      for (let i = 0; i < line.length; i++) {
        const char = line[i]
        const nextChar = line[i + 1]

        if (char === '"') {
          if (inQuotes && nextChar === '"') {
            current += '"'
            i++
          } else {
            inQuotes = !inQuotes
          }
        } else if (char === ',' && !inQuotes) {
          result.push(current)
          current = ''
        } else {
          current += char
        }
      }
      result.push(current)
      return result
    },
    initMap() {
      this.map = L.map('map', {
        center: [46.2276, 2.2137],
        zoom: 6,
        minZoom: 4,
        maxZoom: 13
      })

      L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
        attribution: '© OpenStreetMap © CartoDB',
        maxZoom: 19
      }).addTo(this.map)

      this.loadFranceGeometry()

      this.addMarkers()
      this.addDOMTOMMarkers()
      this.initDOMTOMMaps()

      this.addLegend()
      this.addScale()
    },
    addDOMTOMMarkers() {
      let domtomCount = 0
      const domtomByTerritory = {}
      
      this.data.forEach(person => {
        const dept = person.departement ? person.departement.trim() : ''
        
        let territory = null
        if (dept === 'Guadeloupe') {
          territory = 'Guadeloupe'
        } else if (dept === 'Martinique') {
          territory = 'Martinique'
        } else if (dept === 'Guyane') {
          territory = 'Guyane'
        } else if (dept === 'Mayotte') {
          territory = 'Mayotte'
        } else if (dept === 'La Réunion') {
          territory = 'La Réunion'
        } else if (dept === 'Nouvelle-Calédonie') {
          territory = 'Nouvelle-Calédonie'
        }
        
        if (!territory) return
        
        if (!domtomByTerritory[territory]) {
          domtomByTerritory[territory] = []
        }
        domtomByTerritory[territory].push(person)
      })
      
      const territoryCoords = {
        'Guadeloupe': [16.2415, -61.5331],
        'Martinique': [14.6037, -61.0594],
        'Guyane': [4.9333, -52.3333],
        'Mayotte': [-12.7804, 45.2280],
        'La Réunion': [-20.8823, 55.4504],
        'Nouvelle-Calédonie': [-22.2758, 166.4580]
      }
      
      Object.entries(domtomByTerritory).forEach(([territory, persons]) => {
        const baseCoords = territoryCoords[territory]
        
        persons.forEach((person, index) => {
          let coords = baseCoords
          
          if (persons.length > 1) {
            const jitterAmount = 0.05 * (index + 1) / persons.length
            const angle = (index / persons.length) * Math.PI * 2
            coords = [
              baseCoords[0] + Math.cos(angle) * jitterAmount,
              baseCoords[1] + Math.sin(angle) * jitterAmount
            ]
          }
          
          domtomCount++
          const marker = L.circleMarker(coords, {
            radius: 5,
            fillColor: '#e74c3c',
            color: '#c0392b',
            weight: 2,
            opacity: 1,
            fillOpacity: 0.7
          }).addTo(this.map)

          marker.on('click', () => {
            this.selectedPerson = person
          })
        })
      })
      
      console.log('DOM-TOM markers added (with jitter):', domtomCount)
    },
    initDOMTOMMaps() {
      const domtomConfig = [
        { id: 'map-guadeloupe', territory: 'Guadeloupe', center: [16.2415, -61.5331], spread: 0.05 },
        { id: 'map-martinique', territory: 'Martinique', center: [14.6037, -61.0594], spread: 0.04 },
        { id: 'map-guyane', territory: 'Guyane', center: [4.9333, -52.3333], spread: 0.06 },
        { id: 'map-mayotte', territory: 'Mayotte', center: [-12.7804, 45.2280], spread: 0.01 },
        { id: 'map-reunion', territory: 'La Réunion', center: [-21.0, 55.4504], spread: 0.04 },
        { id: 'map-nouvelle-caledonie', territory: 'Nouvelle-Calédonie', center: [-22.0, 166.4580], spread: 0.02 }
      ]
      
      domtomConfig.forEach(config => {
        const miniMap = L.map(config.id, {
          center: config.center,
          zoom: 8,
          zoomControl: false,
          dragging: true,
          touchZoom: true,
          doubleClickZoom: true,
          scrollWheelZoom: true,
          attributionControl: false
        })
        
        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
          maxZoom: 19,
          attribution: ''
        }).addTo(miniMap)
        
        const territoryPoints = this.data.filter(p => {
          const dept = p.departement ? p.departement.trim() : ''
          return dept === config.territory
        })
        
        territoryPoints.forEach((person, index) => {
          let coords = config.center
          
          if (territoryPoints.length > 0) {
            const spreadLat = (Math.random() - 0.5) * 2 * config.spread
            const spreadLng = (Math.random() - 0.5) * 2 * config.spread
            
            coords = [
              config.center[0] + spreadLat,
              config.center[1] + spreadLng
            ]
          }
          
          const marker = L.circleMarker(coords, {
            radius: 5,
            fillColor: '#e74c3c',
            color: '#c0392b',
            weight: 2,
            opacity: 1,
            fillOpacity: 0.7
          }).addTo(miniMap)
          
          marker.on('click', () => {
            this.selectedPerson = person
          })
        })
      })
    },
    async loadFranceGeometry() {
      try {
        const response = await fetch('/ne_coastline.geojson')
        const geojson = await response.json()
        L.geoJSON(geojson, {
          style: {
            color: '#ccc',
            weight: 1,
            opacity: 0.5
          }
        }).addTo(this.map)
      } catch (error) {
        console.error('Erreur chargement géométrie:', error)
      }
    },
    addMarkers() {
      const cityDeaths = {}

      this.data.forEach(person => {
        const dept = person.departement ? person.departement.trim() : ''
        if (dept === 'Guadeloupe' || dept === 'Martinique' || dept === 'Guyane' || 
            dept === 'Mayotte' || dept === 'La Réunion' || dept === 'Nouvelle-Calédonie') {
          return
        }

        const city = person.ville
        if (!cityDeaths[city]) {
          cityDeaths[city] = []
        }
        cityDeaths[city].push(person)
      })

      const majorCities = new Set(['paris','lyon','marseille','toulouse','bordeaux','lille','nice','nantes','strasbourg','montpellier'])

      Object.entries(cityDeaths).forEach(([city, persons]) => {
        const baseCoords = this.cityCoordinates[city]
        if (!baseCoords) return

        persons.forEach((person, index) => {
          let coords = baseCoords
          const cityKey = city ? city.toLowerCase() : ''

          if (majorCities.has(cityKey)) {
            const r = 0.03 * Math.random()
            const angle = Math.random() * Math.PI * 2
            coords = [
              baseCoords[0] + Math.cos(angle) * r,
              baseCoords[1] + Math.sin(angle) * r
            ]
          } else if (persons.length > 1) {
            const jitterAmount = 0.01 * (index + 1) / persons.length
            const angle = (index / persons.length) * Math.PI * 2
            coords = [
              baseCoords[0] + Math.cos(angle) * jitterAmount,
              baseCoords[1] + Math.sin(angle) * jitterAmount
            ]
          }

          const marker = L.circleMarker(coords, {
            radius: 5,
            fillColor: '#e74c3c',
            color: '#c0392b',
            weight: 2,
            opacity: 1,
            fillOpacity: 0.7
          }).addTo(this.map)

          marker.on('click', () => {
            this.selectedPerson = person
          })

          this.markers.push(marker)
        })
      })
    },
    addLegend() {
      const legend = L.control({ position: 'bottomleft' })

      legend.onAdd = () => {
        const div = L.DomUtil.create('div', 'legend')
        div.style.marginLeft = '280px'
        div.innerHTML = `
          <div style="background: #0b0b0b; color: #e74c3c; padding: 12px; border-radius: 6px; box-shadow: 0 0 10px rgba(0,0,0,0.35); border: 2px solid #e74c3c; font-family: 'Courier New', Courier, monospace;">
            <p style="margin: 2px 0; font-size: 13px; display: flex; align-items: center; gap: 6px;">
              <span style="display: inline-block; width: 14px; height: 14px; background: #e74c3c; border: 1px solid #c0392b; border-radius: 50%;"></span>
              individu tué.e par la police française
            </p>
            <p style="margin: 2px 0; font-size: 13px; color: #e74c3c;">Total: ${this.data.length} morts</p>
            <p style="margin: 6px 0 2px 0; font-size: 11px; color: #e74c3c; opacity: 0.85;">Source : basta.media</p>
          </div>
        `
        return div
      }

      legend.addTo(this.map)
    },
    addScale() {
      L.control.scale({ position: 'bottomright', imperial: false, metric: true }).addTo(this.map)
    }
  }
}
</script>

<style scoped>
.copskill-view {
  width: 100%;
  height: 100vh;
  position: relative;
  background: #1a1a1a;
  color: #fff;
  display: flex;
  flex-direction: column;
  align-items: stretch;
  justify-content: stretch;
}

.map-wrapper {
  flex: 1;
  position: relative;
  display: flex;
  gap: 0;
}

.main-map {
  flex: 1;
  z-index: 1;
}

#map {
  width: 100%;
  height: 100%;
}



.map-title {
  background: #0b0b0b;
  padding: 12px 16px;
  border-radius: 10px;
  margin: 0;
  font-size: 1.05rem;
  font-weight: 700;
  color: #e74c3c;
  border: 2px solid #e74c3c;
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.4);
}

.leaflet-top.leaflet-left .leaflet-control-zoom {
  border: 2px solid #e74c3c;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.35);
  background: #0b0b0b;
}

:deep(.leaflet-control-zoom a) {
  background: #0b0b0b !important;
  color: #e74c3c !important;
  border-bottom: 1px solid rgba(231, 76, 60, 0.6) !important;
}

:deep(.leaflet-control-zoom a:hover) {
  background: #1a1a1a !important;
  color: #e74c3c !important;
}

.top-bar {
  position: absolute;
  top: 10px;
  right: 10px;
  z-index: 1000;
  display: flex;
  align-items: center;
  gap: 10px;
}

.back-btn {
  padding: 10px 18px;
  background: #0b0b0b;
  border: 2px solid #e74c3c;
  border-radius: 10px;
  cursor: pointer;
  font-size: 0.95rem;
  font-weight: 700;
  color: #e74c3c;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
  transition: all 0.2s ease;
}

.back-btn:hover {
  background: #1a1a1a;
  transform: translateY(-1px);
}

.popup-info {
  position: absolute;
  top: auto;
  right: 12px;
  bottom: 70px;
  left: auto;
  z-index: 999;
  background: #0b0b0b;
  color: #e74c3c;
  border: 2px solid #e74c3c;
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
  width: max-content;
  max-width: 90vw;
  max-height: 400px;
  overflow-y: auto;
  overflow-x: auto;
}

.popup-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px;
  border-bottom: 2px solid #e74c3c;
  background: #111;
}

.popup-header h3 {
  margin: 0;
  color: #e74c3c;
  font-size: 1.1rem;
}

.popup-header button {
  background: none;
  border: none;
  font-size: 1.5rem;
  color: #e74c3c;
  cursor: pointer;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.popup-header button:hover {
  color: #333;
}

.popup-body {
  padding: 15px;
  color: #e74c3c;
  font-size: 0.9rem;
  background: #0b0b0b;
}

.popup-body p {
  margin: 8px 0;
  line-height: 1.4;
  white-space: nowrap;
}

.popup-body strong {
  color: #e74c3c;
  display: inline-block;
  min-width: 140px;
}

:deep(.leaflet-control-scale) {
  background: rgba(0, 0, 0, 0.85) !important;
  color: #fff;
  box-shadow: none !important;
}

:deep(.leaflet-control-scale-line) {
  border: 2px solid #e74c3c !important;
  background: #0b0b0b !important;
  color: #e74c3c !important;
  box-shadow: none !important;
}

:deep(.leaflet-bottom.leaflet-left .legend) {
  margin: 6px;
}

:deep(.leaflet-control-attribution) {
  background: rgba(0, 0, 0, 0.75) !important;
  color: #e74c3c !important;
  border: 1px solid #e74c3c !important;
  padding: 2px 6px !important;
}

:deep(.leaflet-control-attribution a) {
  color: #e74c3c !important;
}

.domtom-container {
  position: absolute;
  top: 10px;
  left: 10px;
  bottom: 10px;
  width: 230px;
  z-index: 500;
  pointer-events: auto;
  display: flex;
  flex-direction: column;
}

.domtom-grid {
  display: grid;
  grid-template-columns: 1fr;
  grid-template-rows: repeat(6, 1fr);
  gap: 8px;
  padding: 4px;
  background: rgba(11, 11, 11, 0.9);
  border: 2px solid #e74c3c;
  border-radius: 6px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
  flex: 1;
  min-height: calc(100vh - 100px);
  width: 230px;
  overflow: hidden;
}

.domtom-map {
  position: relative;
  width: 100%;
  height: 100%;
  border: 1px solid #e74c3c;
  border-radius: 6px;
  overflow: hidden;
  background: #1a1a1a;
}

.domtom-map .map {
  width: 100%;
  height: 100%;
  position: relative;
}

.map-label {
  display: none;
}

:deep(.domtom-map .leaflet-container) {
  background: #1a1a1a;
}

:deep(.domtom-map .leaflet-control-zoom) {
  border: 1px solid #e74c3c !important;
  background: #0b0b0b !important;
  box-shadow: none !important;
}

:deep(.domtom-map .leaflet-control-zoom a) {
  background: #0b0b0b !important;
  color: #e74c3c !important;
  border-bottom: 1px solid rgba(231, 76, 60, 0.4) !important;
  width: 24px !important;
  height: 24px !important;
  line-height: 24px !important;
  font-size: 0.8rem !important;
}

:deep(.domtom-map .leaflet-control-zoom a:hover) {
  background: #1a1a1a !important;
  color: #e74c3c !important;
}

:deep(.domtom-map .leaflet-control-attribution) {
  display: none !important;
}

</style>
