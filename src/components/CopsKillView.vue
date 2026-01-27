<template>
  <div class="copskill-view">
    <div class="map-wrapper">
      <div class="domtom-container">
        <h3>DOM-TOM</h3>
        <div class="domtom-grid">
          <div class="domtom-map" id="map-domtom-guyane"></div>
          <div class="domtom-map" id="map-domtom-reunion"></div>
          <div class="domtom-map" id="map-domtom-mayotte"></div>
          <div class="domtom-map" id="map-domtom-antilles"></div>
        </div>
      </div>

      <div class="top-bar">
        <h1 class="map-title">Morts de la Police Française (1977-2024)</h1>
        <button class="back-btn" @click="$emit('back')">← Retour</button>
      </div>
      
      <!-- Carte principale -->
      <div id="map" class="main-map"></div>
      
      <!-- Popup au clic -->
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

      // Charger la géométrie France
      this.loadFranceGeometry()
      
      // Ajouter les marqueurs
      this.addMarkers()
      
      // Ajouter légende et contrôles
      this.addLegend()
      this.addScale()
      
      // Initialiser les cartes DOM-TOM
      this.initDOMTOMMaps()
    },
    initDOMTOMMaps() {
      const domtomConfigs = [
        { id: 'map-domtom-guyane', center: [3.9, -53.1], zoom: 6, match: ['guyane'] },
        { id: 'map-domtom-reunion', center: [-21.13, 55.53], zoom: 8, match: ['réunion', 'la réunion', 'reunion'] },
        { id: 'map-domtom-mayotte', center: [-12.76, 45.17], zoom: 8, match: ['mayotte'] },
        { id: 'map-domtom-antilles', center: [15.25, -61.1], zoom: 6, match: ['guadeloupe', 'martinique'] }
      ]

      domtomConfigs.forEach(cfg => {
        const domMap = L.map(cfg.id, {
          zoom: cfg.zoom,
          minZoom: cfg.zoom - 2,
          maxZoom: cfg.zoom + 3,
          attributionControl: false
        })

        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
          attribution: '© OpenStreetMap © CartoDB',
          maxZoom: 19
        }).addTo(domMap)

        domMap.setView(cfg.center, cfg.zoom)

        this.data.forEach(person => {
          const dept = person.departement.toLowerCase()
          const ville = person.ville.toLowerCase()
          const matches = cfg.match.some(m => dept.includes(m) || ville.includes(m))
          if (!matches) return

          const marker = L.circleMarker(cfg.center, {
            radius: 4,
            fillColor: '#e74c3c',
            color: '#c0392b',
            weight: 1.5,
            opacity: 1,
            fillOpacity: 0.7
          }).addTo(domMap)

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
      
      // Grouper les morts par ville
      this.data.forEach(person => {
        const city = person.ville
        if (!cityDeaths[city]) {
          cityDeaths[city] = []
        }
        cityDeaths[city].push(person)
      })
      
      const majorCities = new Set(['paris','lyon','marseille','toulouse','bordeaux','lille','nice','nantes','strasbourg','montpellier'])

      // Ajouter marqueurs
      Object.entries(cityDeaths).forEach(([city, persons]) => {
        const baseCoords = this.cityCoordinates[city]
        if (!baseCoords) return
        
        persons.forEach((person, index) => {
          let coords = baseCoords
          const cityKey = city ? city.toLowerCase() : ''

          // Pour les grandes villes, dispersion aléatoire dans un rayon ~0.03°
          if (majorCities.has(cityKey)) {
            const r = 0.03 * Math.random()
            const angle = Math.random() * Math.PI * 2
            coords = [
              baseCoords[0] + Math.cos(angle) * r,
              baseCoords[1] + Math.sin(angle) * r
            ]
          } else if (persons.length > 1) {
            // Jitter si plusieurs personnes dans la même ville
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
        div.innerHTML = `
          <div style="background: #0b0b0b; color: #e74c3c; padding: 12px; border-radius: 6px; box-shadow: 0 0 10px rgba(0,0,0,0.35); border: 2px solid #e74c3c;">
            <p style="margin: 2px 0; font-size: 13px; display: flex; align-items: center; gap: 6px;">
              <span style="display: inline-block; width: 14px; height: 14px; background: #e74c3c; border: 1px solid #c0392b; border-radius: 50%;"></span>
              individu tué.e par la police française
            </p>
            <p style="margin: 2px 0; font-size: 13px; color: #e74c3c;">Total: ${this.data.length} morts</p>
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

.domtom-container {
  width: 320px;
  min-width: 220px;
  max-width: 520px;
  height: 100%;
  background: #0b0b0b;
  border-right: 3px solid #e74c3c;
  display: flex;
  flex-direction: column;
  z-index: 100;
  box-shadow: 8px 0 18px rgba(0, 0, 0, 0.35);
  resize: horizontal;
  overflow: auto;
  cursor: col-resize;
}

.domtom-container h3 {
  margin: 12px;
  font-size: 1rem;
  color: #e74c3c;
  text-align: center;
  border-bottom: 1px solid rgba(231, 76, 60, 0.4);
  padding-bottom: 12px;
}

.domtom-grid {
  flex: 1;
  display: grid;
  grid-template-columns: 1fr 1fr;
  grid-template-rows: 1fr 1fr;
  gap: 8px;
  padding: 12px;
}

.domtom-map {
  background: #111;
  border: 1px solid rgba(231, 76, 60, 0.35);
  border-radius: 6px;
  overflow: hidden;
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

</style>
