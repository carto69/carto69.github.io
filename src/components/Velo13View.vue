<template>
  <div class="velo13-container">
    <button class="back-button" @click="$emit('back')" title="Retour à l'accueil">← Accueil</button>
    <div id="velo13-map" class="map-canvas"></div>
    <div class="map-title">le 13 en vélo</div>

    <div class="stats-sidebar">
      <h2>Mes trajets</h2>
      <div class="stat-item"><span class="stat-label">Trajets</span><span class="stat-value">0</span></div>
      <div class="stat-item"><span class="stat-label">Distance</span><span class="stat-value">0 km</span></div>
      <div class="stat-item"><span class="stat-label">CO₂ économisé</span><span class="stat-value">0 kg</span></div>
      <div class="stat-item"><span class="stat-label">Vitesse moyenne</span><span class="stat-value">0 km/h</span></div>
      <div class="stat-item"><span class="stat-label">Segments tracés</span><span class="stat-value">0</span></div>
      <div class="stat-item"><span class="stat-label">Durée moyenne</span><span class="stat-value">0 min</span></div>

      <hr class="sidebar-divider" />
      <div class="map-controls" style="display:flex;flex-wrap:wrap;align-items:center;gap:1em;">
        <label>
          <input type="checkbox" v-model="showStations" @change="toggleStations" disabled />
          Stations
        </label>
        <label>
          <input type="checkbox" v-model="showHotspot" @change="toggleHotspot" disabled />
          Heatmap
        </label>
        <div class="trajet-selector" style="margin:0;">
          <label style="margin-right:0.5em;">Analyser un trajet:</label>
          <select v-model="selectedTripIndex" @change="onTripSelected" class="trip-select" disabled>
            <option :value="-1">-- Sélectionner --</option>
          </select>
        </div>
      </div>

      <div v-if="selectedTripIndex >= 0" class="trip-details"></div>
    </div>
  </div>
</template>

<script>
import maplibregl from 'maplibre-gl'

export default {
  name: 'Velo13View',
  data() {
    return {
      map: null,
      showStations: false,
      showHotspot: false,
      selectedTripIndex: -1,
      displayedTrips: []
    }
  },
  mounted() {
    this.initMap()
  },
  methods: {
    initMap() {
      this.map = new maplibregl.Map({
        container: 'velo13-map',
        style: 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json',
        center: [5.3698, 43.2965],
        zoom: 12
      })
      this.map.addControl(new maplibregl.NavigationControl(), 'top-right')
      this.map.addControl(new maplibregl.ScaleControl({ unit: 'metric' }), 'bottom-left')
      this.map.on('load', () => {})
    },
    toggleStations() {
    },
    toggleHotspot() {
      if (!this.map) return
      if (this.showHotspot) {
        this.displayHeatmap()
      } else if (this.map.getLayer && this.map.getLayer('velo13-heatmap')) {
        this.map.setLayoutProperty('velo13-heatmap', 'visibility', 'none')
      }
    },
    displayHeatmap() {
      if (!this.map) return
      const heatFeatures = []
      if (!this.map.getSource('velo13-heatmap')) {
        this.map.addSource('velo13-heatmap', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features: heatFeatures }
        })
        this.map.addLayer({
          id: 'velo13-heatmap',
          type: 'heatmap',
          source: 'velo13-heatmap',
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
              1, '#00D9FF'
            ],
            'heatmap-radius': 32,
            'heatmap-opacity': 0.8
          }
        })
      } else {
        this.map.getSource('velo13-heatmap').setData({ type: 'FeatureCollection', features: heatFeatures })
        this.map.setLayoutProperty('velo13-heatmap', 'visibility', 'visible')
      }
    },
    onTripSelected() {}
  },
  beforeUnmount() {
    if (this.map) this.map.remove()
  }
}
</script>

<style scoped>
.velo13-container { position: relative; width: 100%; height: 100vh; background: #000; }
.map-canvas { width: 100%; height: 100%; }
.map-title { position: absolute; top: 16px; left: 50%; transform: translateX(-50%); background: rgba(0,0,0,0.9); padding: 12px 24px; border-radius: 8px; border: 2px solid #00D9FF; font-size: 20px; font-weight: 800; color: #00D9FF; box-shadow: 0 2px 8px rgba(0,0,0,0.3); z-index: 1; }
.stats-sidebar { position: absolute; top: 50%; left: 20px; transform: translateY(-50%); background: rgba(0,0,0,0.9); border: 1px solid rgba(0, 217, 255, 0.4); padding: 10px 12px; border-radius: 8px; font-size: 11px; color: #fff; z-index: 10; max-width: 220px; box-shadow: 0 4px 16px rgba(0,0,0,0.5); }
.stats-sidebar h2 { margin: 0 0 12px 0; font-size: 13px; color: #00D9FF; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; }
.stat-item { display: flex; justify-content: space-between; align-items: center; margin-bottom: 5px; padding: 3px 0; border-bottom: 1px solid rgba(0, 217, 255, 0.2); }
.stat-item:last-child { border-bottom: none; margin-bottom: 0; }
.stat-label { font-weight: 500; color: #ccc; }
.stat-value { font-weight: 700; color: #00D9FF; text-align: right; min-width: 62px; }
.sidebar-divider { border: none; border-top: 1px solid rgba(0, 217, 255, 0.3); margin: 12px 0; }
.map-controls { margin: 8px 0; font-size: 11px; }
.map-controls label { display: flex; align-items: center; color: #00D9FF; cursor: pointer; font-weight: 600; gap: 6px; }
.map-controls input[type="checkbox"] { width: 14px; height: 14px; cursor: pointer; accent-color: #00D9FF; }
.trajet-selector { margin: 8px 0; }
.trajet-selector label { display: block; font-size: 10px; font-weight: 600; color: #00D9FF; margin-bottom: 6px; text-transform: uppercase; letter-spacing: 0.5px; }
.trip-select { width: 100%; padding: 5px; background: rgba(0, 217, 255, 0.1); border: 1px solid rgba(0, 217, 255, 0.5); border-radius: 4px; color: #fff; font-size: 10px; cursor: pointer; }
.back-button { position: absolute; top: 16px; left: 16px; background: #000; color: #00D9FF; border: 1px solid #00D9FF; padding: 8px 16px; border-radius: 6px; font-size: 13px; font-weight: 600; cursor: pointer; box-shadow: 0 2px 8px rgba(0,0,0,0.25); z-index: 10; transition: all 0.3s ease; }
.back-button:hover { background: #0b0b0b; box-shadow: 0 4px 12px rgba(0,0,0,0.3); transform: translateY(-2px); }
@media (max-width: 768px) {
  .stats-sidebar { max-width: 100%; width: calc(100% - 40px); left: 20px; right: 20px; top: 50%; transform: translateY(-50%); }
  .map-title { font-size: 16px; padding: 10px 16px; left: 50%; top: 56px; transform: translateX(-50%); }
  .back-button { padding: 8px 16px; font-size: 12px; }
}

:deep(.maplibregl-ctrl-zoom-in),
:deep(.maplibregl-ctrl-zoom-out),
:deep(.maplibregl-ctrl-compass) {
  background-color: #000 !important;
  border: 1px solid #00D9FF !important;
  color: #00D9FF !important;
}

:deep(.maplibregl-ctrl-zoom-in::before),
:deep(.maplibregl-ctrl-zoom-out::before) {
  background-color: #00D9FF !important;
}

:deep(.maplibregl-ctrl-zoom-in:hover),
:deep(.maplibregl-ctrl-zoom-out:hover),
:deep(.maplibregl-ctrl-compass:hover) {
  background-color: rgba(0, 217, 255, 0.1) !important;
}

:deep(.maplibregl-ctrl-compass::before) {
  background-color: #00D9FF !important;
}

:deep(.maplibregl-ctrl-scale) {
  background-color: #000 !important;
  border: 1px solid #00D9FF !important;
  color: #00D9FF !important;
}
</style>
