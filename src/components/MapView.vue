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
      showParkings: true
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
      // Use an empty/neutral style so only our GeoJSON layers and image overlays are visible
      const blankStyle = {
        version: 8,
        name: 'Blank',
        sources: {},
        layers: [
          {
            id: 'background',
            type: 'background',
            paint: { 'background-color': '#ffffff' }
          }
        ]
      }

      this.map = new mapboxgl.Map({
        container: this.$refs.mapContainer,
        style: blankStyle,
        // Centrer sur Paris (Italie 2 est à Paris)
        center: [2.3522, 48.8566],
        zoom: 16
      })

      this.map.on('load', async () => {
        // add navigation controls
        this.map.addControl(new mapboxgl.NavigationControl({ showCompass: true }))

        try {
          // try several possible locations for map.json (dev / build differences)
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
          if (!json) throw new Error('map.json introuvable ou invalide (essayé: ' + candidates.join(',') + ')')
          // Expecting GeoJSON FeatureCollection or similar structure
          this.rawData = json
          this.featuresCount = Array.isArray(json.features) ? json.features.length : 0
          this.loadError = null
          this.prepareFloors()
          // restore previously selected floor if present
          this.loadSelectedFloorFromStorage()
          this.addSourcesAndLayers()
          // load overlays from storage and add them to the map
          this.loadOverlaysFromStorage()
          // fit map to the features bounds so the centre commercial is visible
          this.fitToFeatures()
        } catch (err) {
          console.error('Erreur en chargeant map.json', err)
          this.loadError = String(err && err.message ? err.message : err)
          this.rawData = null
          this.featuresCount = 0
        }
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
    addSourcesAndLayers() {
      // floor source: full GeoJSON
      if (this.map.getSource('floor-data')) this.map.removeSource('floor-data')
      this.map.addSource('floor-data', { type: 'geojson', data: this.rawData })
      // All-features outline (background) - show geometry of all floors
      if (this.map.getLayer('all-line')) this.map.removeLayer('all-line')
      this.map.addLayer({
        id: 'all-line',
        type: 'line',
        source: 'floor-data',
        paint: { 'line-color': '#666', 'line-width': 1, 'line-opacity': 0.45 }
      })

      // floor fill layer (filtered by selected floor) - highlighted
      if (this.map.getLayer('floor-fill')) this.map.removeLayer('floor-fill')
      this.map.addLayer({
        id: 'floor-fill',
        type: 'fill',
        source: 'floor-data',
        paint: {
          'fill-color': '#6baed6',
          'fill-opacity': 0.45
        },
        filter: ['==', ['to-string', ['coalesce', ['get', 'floor'], ['get', 'level'], '0']], String(this.selectedFloor)]
      })

      // outline for selected floor
      if (this.map.getLayer('floor-line')) this.map.removeLayer('floor-line')
      this.map.addLayer({
        id: 'floor-line',
        type: 'line',
        source: 'floor-data',
        paint: { 'line-color': '#2171b5', 'line-width': 2 },
        filter: ['==', ['to-string', ['coalesce', ['get', 'floor'], ['get', 'level'], '0']], String(this.selectedFloor)]
      })

      // parkings source (derived)
      const parkingFeatures = (this.rawData.features || []).filter(f => {
        const t = (f.properties && (f.properties.type || f.properties.TYPE || f.properties.kind)) || ''
        const pname = String(t).toLowerCase()
        return pname.includes('park') || pname.includes('parking') || (f.properties && f.properties.parking === true)
      })

      const parkGeo = { type: 'FeatureCollection', features: parkingFeatures }
      if (this.map.getSource('parking-data')) this.map.removeSource('parking-data')
      this.map.addSource('parking-data', { type: 'geojson', data: parkGeo })

      if (this.map.getLayer('parking-layer')) this.map.removeLayer('parking-layer')
      this.map.addLayer({
        id: 'parking-layer',
        type: 'circle',
        source: 'parking-data',
        paint: {
          'circle-radius': 6,
          'circle-color': '#fdae6b'
        }
      })

      this.updateParking()
      this.updateOverlaysForFloor()
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
    }
  }
}
</script>

<style scoped>
.map-page { display: flex; height: calc(100vh - 60px); }
.controls { width: 220px; padding: 12px; background:#fff; box-shadow: 0 0 6px rgba(0,0,0,0.08); z-index:5; overflow-y: auto; }
.map-container { flex:1 }
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
