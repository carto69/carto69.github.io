<template>
  <div class="map-page">
    <aside class="controls">
      <button class="back-btn" @click="$emit('back')">← Retour</button>
      
      <div class="floor-selector">
        <label>Étage:</label>
        <div class="floor-buttons">
          <button v-for="f in floors" :key="f" :class="{ active: String(f) === String(selectedFloor) }" @click="selectFloor(f)">{{ f }}</button>
        </div>
      </div>

      <label>
        <input type="checkbox" v-model="showParkings" @change="updateParking" /> Regrouper parkings
      </label>

      <div class="legend">
        <div><span class="dot floor"></span> Plan étage</div>
        <div><span class="dot parking"></span> Parkings</div>
      </div>

      <hr />
      <div style="display:flex;gap:8px;align-items:center;justify-content:space-between">
        <h3>Plans (overlay)</h3>
        <button @click.prevent="fitToFeatures">Centrer sur le centre commercial</button>
      </div>
      <label>Étage pour plan:
        <select v-model="newOverlayFloor">
          <option v-for="f in floors" :key="f" :value="f">{{ f }}</option>
        </select>
      </label>
      <label>Nom:
        <input type="text" v-model="newOverlayName" placeholder="Ex: Niveau 1" />
      </label>
      <label>URL image:
        <input type="text" v-model="newOverlayUrl" placeholder="https://.../plan.png" />
        <button @click.prevent="addOverlayFromUrl">Ajouter depuis URL</button>
      </label>
      <label>Ou upload:
        <input type="file" accept="image/*" @change="addOverlayFromFile" />
      </label>

      <div class="overlay-list">
        <div v-for="o in overlays" :key="o.id" class="overlay-item">
          <strong>{{ o.name }}</strong> — étage {{ o.floor }}
          <div>
            <button @click="toggleOverlayVisibility(o)">{{ o.visible ? 'Masquer' : 'Afficher' }}</button>
            <button @click="removeOverlay(o.id)">Supprimer</button>
          </div>
        </div>
      </div>
      <div class="debug">
        <div v-if="loadError" style="color:#b00">Erreur chargement map.json: {{ loadError }}</div>
        <div>Features chargées: {{ featuresCount }}</div>
      </div>
    </aside>
    <div ref="mapContainer" class="map-container"></div>
  </div>
</template>

<script>
const mapboxgl = window.mapboxgl

export default {
  name: 'MapView',
  data() {
    return {
      map: null,
      floors: [],
      selectedFloor: null,
      rawData: null,
      loadError: null,
      featuresCount: 0,
      token: '',
      overlays: [],
      newOverlayUrl: '',
      newOverlayName: '',
      newOverlayFloor: null,
      newOverlayBounds: null,
      showParkings: true,
    }
  },
  mounted() {
    const t = import.meta.env.VITE_MAPBOX_TOKEN || ''
    if (!t) {
      console.warn('No Mapbox token set. See .env.example')
    }
    this.token = t
    // Disable Mapbox telemetry/events which some adblockers flag and block.
    // This avoids console errors like `ERR_BLOCKED_BY_CLIENT` for events.mapbox.com.
    try { if (typeof mapboxgl.setTelemetryEnabled === 'function') mapboxgl.setTelemetryEnabled(false) } catch(e) {}
    mapboxgl.accessToken = this.token

    this.initMap()
  },
  methods: {
    async initMap() {
      // Style de base : fond blanc
      const style = {
        version: 8,
        name: 'White with Littorals',
        sources: {
          'naturalearth-land': {
            type: 'vector',
            url: 'mapbox://mapbox.natural-earth-hypso',
          },
          'naturalearth-coastline': {
            type: 'vector',
            url: 'mapbox://mapbox.natural-earth-2',
          },
          'satellite': {
            type: 'raster',
            url: 'mapbox://mapbox.satellite',
            tileSize: 256
          }
        },
        layers: [
          {
            id: 'background',
            type: 'background',
            paint: { 'background-color': '#ffffff' }
          },
          // Couche satellite (masquée par défaut)
          {
            id: 'satellite',
            type: 'raster',
            source: 'satellite',
            layout: { visibility: 'none' }
          },
          // Littoraux (traits noirs)
          {
            id: 'coastline',
            type: 'line',
            source: 'naturalearth-coastline',
            'source-layer': 'ne_10m_coastline',
            paint: {
              'line-color': '#111',
              'line-width': 1.2
            }
          }
        ]
      }

      this.map = new mapboxgl.Map({
        container: this.$refs.mapContainer,
        style: style,
        center: [2.3522, 48.8566],
        zoom: 16
      })

      this.map.on('load', async () => {
        // add navigation controls
        this.map.addControl(new mapboxgl.NavigationControl({ showCompass: true }))
        // Essayez de charger map.json, mais n'empêchez pas l'affichage du fond si absent
        const candidates = ['/map.json', 'map.json', './map.json', '/public/map.json']
        let json = null
        for (const url of candidates) {
          try {
            const r = await fetch(url)
            if (!r.ok) continue
            const j = await r.json()
            if (j && Array.isArray(j.features)) { json = j; break }
          } catch (e) {
            // ignore and try next
          }
        }
        if (json) {
          // Si map.json trouvé, on continue comme avant
          this.rawData = json
          this.featuresCount = Array.isArray(json.features) ? json.features.length : 0
          this.loadError = null
          this.prepareFloors()
          this.loadSelectedFloorFromStorage()
          this.addSourcesAndLayers()
          this.loadOverlaysFromStorage()
          this.fitToFeatures()
        } else {
          // Si map.json absent, on centre sur la France et affiche le fond blanc + littoraux
          this.loadError = 'Aucun plan chargé, fond blanc + littoraux seulement.'
          try {
            this.map.setCenter([2, 47]);
            this.map.setZoom(5);
          } catch (e) {
            this.loadError += ' (Erreur centrage: ' + e + ')';
          }
        }
        // Vérification du chargement de la carte Mapbox
        this.map.on('error', (e) => {
          if (e && e.error && e.error.message && e.error.message.includes('access token')) {
            this.loadError = 'Erreur Mapbox : problème de token ou de droits.';
          }
        });
      })
    },
    // called by floor button
    selectFloor(f) {
      this.selectedFloor = String(f)
      this.updateFloor()
    },
      fitToFeatures() {
        if (!this.rawData || !this.rawData.features || !this.map) return
        const coords = []
        const pushCoord = (c) => {
          if (Array.isArray(c) && typeof c[0] === 'number') {
            coords.push(c)
          } else if (Array.isArray(c)) {
            c.forEach(pushCoord)
          }
        }
        this.rawData.features.forEach(f => {
          if (f.geometry && f.geometry.coordinates) pushCoord(f.geometry.coordinates)
        })
        if (!coords.length) return
        let minLng = Infinity, minLat = Infinity, maxLng = -Infinity, maxLat = -Infinity
        coords.forEach(c => {
          const [lng, lat] = c
          if (lng < minLng) minLng = lng
          if (lng > maxLng) maxLng = lng
          if (lat < minLat) minLat = lat
          if (lat > maxLat) maxLat = lat
        })
        // add small padding
        const padLng = (maxLng - minLng) * 0.12 || 0.002
        const padLat = (maxLat - minLat) * 0.12 || 0.002
        const sw = [minLng - padLng, minLat - padLat]
        const ne = [maxLng + padLng, maxLat + padLat]
        try {
          // Padding équilibré pour centrer la carte avec marges égales
          this.map.fitBounds([sw, ne], { padding: { top: 80, bottom: 80, left: 320, right: 80 }, maxZoom: 18, duration: 700 })
        } catch (e) {
          console.warn('fitBounds failed', e)
        }
      },
    prepareFloors() {
      const features = this.rawData && this.rawData.features ? this.rawData.features : []
      const floorSet = new Set()
      features.forEach(f => {
        const p = f.properties || {}
        const floor = p.floor ?? p.level ?? '0'
        floorSet.add(String(floor))
      })
      const arr = Array.from(floorSet).sort((a, b) => Number(a) - Number(b))
      this.floors = arr.length ? arr : ['0']
      this.selectedFloor = this.floors[0]
    },
    // --- Overlay / floor plan manager ---
    addOverlayFromUrl() {
      const url = (this.newOverlayUrl || '').trim()
      if (!url) return
      const id = `overlay-${Date.now()}`
      const overlay = {
        id,
        name: this.newOverlayName || `Plan ${this.newOverlayFloor}`,
        floor: String(this.newOverlayFloor),
        url,
        visible: true,
        bounds: this.newOverlayBounds ? { ...this.newOverlayBounds } : this.defaultBounds()
      }
      this.overlays.push(overlay)
      this.addImageOverlayToMap(overlay)
      this.saveOverlaysToStorage()
      this.newOverlayUrl = ''
      this.newOverlayName = ''
    },
    addOverlayFromFile(e) {
      const file = e.target.files && e.target.files[0]
      if (!file) return
      const id = `overlay-${Date.now()}`
      const url = URL.createObjectURL(file)
      const overlay = {
        id,
        name: file.name,
        floor: String(this.newOverlayFloor || this.selectedFloor || '0'),
        url,
        visible: true,
        bounds: this.defaultBounds()
      }
      this.overlays.push(overlay)
      this.addImageOverlayToMap(overlay)
      this.saveOverlaysToStorage()
    },
    defaultBounds() {
      // small box around current center
      const center = this.map ? this.map.getCenter() : { lng: 2.3522, lat: 48.8566 }
      const delta = 0.0015 // ~150m
      return { minLng: center.lng - delta, minLat: center.lat - delta, maxLng: center.lng + delta, maxLat: center.lat + delta }
    },
    addImageOverlayToMap(overlay) {
      if (!this.map || !overlay) return
      const srcId = overlay.id
      const coords = this.boundsToCoordinates(overlay.bounds)
      // remove existing if any
      if (this.map.getLayer(srcId + '-layer')) this.map.removeLayer(srcId + '-layer')
      if (this.map.getSource(srcId)) this.map.removeSource(srcId)
      try {
        this.map.addSource(srcId, { type: 'image', url: overlay.url, coordinates: coords })
        this.map.addLayer({
          id: srcId + '-layer',
          type: 'raster',
          source: srcId,
          paint: { 'raster-opacity': overlay.visible ? 1 : 0 }
        }, 'floor-line')
      } catch (err) {
        console.error('Erreur ajout overlay image', err)
      }
    },
    boundsToCoordinates(b) {
      // mapbox image source expects [tl, tr, br, bl]
      return [
        [b.minLng, b.maxLat],
        [b.maxLng, b.maxLat],
        [b.maxLng, b.minLat],
        [b.minLng, b.minLat]
      ]
    },
    removeOverlay(id) {
      const idx = this.overlays.findIndex(o => o.id === id)
      if (idx === -1) return
      const overlay = this.overlays[idx]
      const srcId = id
      if (this.map) {
        if (this.map.getLayer(srcId + '-layer')) this.map.removeLayer(srcId + '-layer')
        if (this.map.getSource(srcId)) this.map.removeSource(srcId)
      }
      // revoke object URL if it was created from a File
      try {
        if (overlay && overlay.url && String(overlay.url).startsWith('blob:')) {
          URL.revokeObjectURL(overlay.url)
        }
      } catch (e) {
        // ignore
      }
      this.overlays.splice(idx, 1)
      this.saveOverlaysToStorage()
    },
    toggleOverlayVisibility(o) {
      o.visible = !o.visible
      const layId = o.id + '-layer'
      if (!this.map || !this.map.getLayer(layId)) return
      const opacity = o.visible ? 1 : 0
      this.map.setPaintProperty(layId, 'raster-opacity', opacity)
      this.saveOverlaysToStorage()
    },
    updateOverlaysForFloor() {
      // show overlays that match selectedFloor, hide others
      this.overlays.forEach(o => {
        const layId = o.id + '-layer'
        if (!this.map || !this.map.getLayer(layId)) return
        const shouldShow = String(o.floor) === String(this.selectedFloor)
        const opacity = (o.visible && shouldShow) ? 1 : 0
        this.map.setPaintProperty(layId, 'raster-opacity', opacity)
      })
      this.saveSelectedFloorToStorage()
    },

    saveOverlaysToStorage() {
      try {
        const data = JSON.stringify(this.overlays)
        localStorage.setItem('italie2_overlays', data)
      } catch (e) { console.warn('save overlays failed', e) }
    },
    loadOverlaysFromStorage() {
      try {
        const raw = localStorage.getItem('italie2_overlays')
        if (!raw) return
        const arr = JSON.parse(raw)
        if (!Array.isArray(arr)) return
        this.overlays = arr
        // add to map
        this.overlays.forEach(o => this.addImageOverlayToMap(o))
        this.updateOverlaysForFloor()
      } catch (e) { console.warn('load overlays failed', e) }
    },
    saveSelectedFloorToStorage() {
      try { localStorage.setItem('italie2_selectedFloor', String(this.selectedFloor)) } catch(e){}
    },
    loadSelectedFloorFromStorage() {
      try {
        const v = localStorage.getItem('italie2_selectedFloor')
        if (v !== null) this.selectedFloor = v
      } catch(e){}
    },
    updateFloor() {
      if (!this.map) return
      const filter = ['==', ['to-string', ['coalesce', ['get', 'floor'], ['get', 'level'], '0']], String(this.selectedFloor)]
      if (this.map.getLayer('floor-fill')) this.map.setFilter('floor-fill', filter)
      if (this.map.getLayer('floor-line')) this.map.setFilter('floor-line', filter)
      this.updateOverlaysForFloor()
    },
    updateParking() {
      if (!this.map) return
      const visibility = this.showParkings ? 'visible' : 'none'
      if (this.map.getLayer('parking-layer')) this.map.setLayoutProperty('parking-layer', 'visibility', visibility)
    },
    // Affiche la vue satellite sur une zone (ex: commune de Lyon)
    // bbox = [minLng, minLat, maxLng, maxLat]
    showSatelliteOnBBox(bbox) {
      if (!this.map) return;
      // Ajoute un masque polygonal blanc sur toute la carte sauf la bbox
      if (this.map.getLayer('satellite-mask')) {
        this.map.removeLayer('satellite-mask')
        this.map.removeSource('satellite-mask')
      }
      // Polygone couvrant le monde entier, avec un trou sur la bbox
      const world = [
        [ [-180, -85], [180, -85], [180, 85], [-180, 85], [-180, -85] ]
      ]
      const [minLng, minLat, maxLng, maxLat] = bbox
      const hole = [
        [minLng, minLat], [maxLng, minLat], [maxLng, maxLat], [minLng, maxLat], [minLng, minLat]
      ]
      const maskGeoJSON = {
        type: 'FeatureCollection',
        features: [
          {
            type: 'Feature',
            geometry: {
              type: 'Polygon',
              coordinates: [world[0], hole]
            }
          }
        ]
      }
      this.map.addSource('satellite-mask', {
        type: 'geojson',
        data: maskGeoJSON
      })
      this.map.addLayer({
        id: 'satellite-mask',
        type: 'fill',
        source: 'satellite-mask',
        paint: {
          'fill-color': '#fff',
          'fill-opacity': 1
        },
        layout: {}
      }, 'coastline')
      // Affiche la couche satellite
      this.map.setLayoutProperty('satellite', 'visibility', 'visible')
    }
  }
}
</script>

<style scoped>
.map-page { display: flex; height: 100vh; }
.controls { width: 220px; padding: 12px; background:#fff; box-shadow: 0 0 6px rgba(0,0,0,0.08); z-index:5; overflow-y: auto; }
.map-container { flex:1; height: 100vh; min-height: 400px; background: #e0e0e0; }
.map-container > div { height: 100% }
.back-btn { width: 100%; padding: 8px 12px; background: #2171b5; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 14px; margin-bottom: 12px; }
.back-btn:hover { background: #1b5fa3; }
.dot { display:inline-block; width:12px; height:12px; border-radius:50%; margin-right:6px }
.dot.floor { background:#6baed6 }
.dot.parking { background:#fdae6b }
/* floor selector styles */
.floor-selector { margin-bottom:8px }
.floor-buttons { display:flex; gap:6px; flex-wrap:wrap; margin-top:6px }
.floor-buttons button { padding:6px 8px; border:1px solid #ddd; background:#fff; cursor:pointer; border-radius:4px }
.floor-buttons button.active { background:#2171b5; color:#fff; border-color:#1b5fa3 }
</style>
