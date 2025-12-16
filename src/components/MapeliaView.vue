<template>
  <div class="mapelia-container">
    <button class="back-button" @click="$emit('back')" title="Retour à l'accueil">← Accueil</button>
    <div id="mapelia-map" class="map-canvas"></div>
    <div class="map-title">Mapelia</div>
    <div class="projection-info">Carte interactive avec parcours personnalisables</div>
  </div>
</template>

<script>
const mapboxgl = window.mapboxgl

export default {
  name: 'MapeliaView',
  mounted() {
    this.initMap()
  },
  methods: {
    initMap() {
      mapboxgl.accessToken = import.meta.env.VITE_MAPBOX_TOKEN
      
      this.map = new mapboxgl.Map({
        container: 'mapelia-map',
        style: 'mapbox://styles/mapbox/outdoors-v12',
        // Centré sur France + Italie
        center: [7, 45],
        zoom: 4.5
      })

      this.map.addControl(new mapboxgl.NavigationControl(), 'top-right')
      this.map.addControl(new mapboxgl.ScaleControl({ unit: 'metric' }), 'bottom-left')
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
.mapelia-container {
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
