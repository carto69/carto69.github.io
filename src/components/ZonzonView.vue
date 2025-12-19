<template>
  <div class="zonzon-container">
    <button class="back-button" @click="$emit('back')" title="Retour à l'accueil">← Accueil</button>
    <div id="zonzon-map" class="map-canvas"></div>
    <div class="map-title">zonzon</div>
    <div class="projection-info">Projection: Equal Earth (vraies proportions)</div>
  </div>
</template>

<script>
const mapboxgl = window.mapboxgl

export default {
  name: 'ZonzonView',
  mounted() {
    this.initMap()
  },
  methods: {
    initMap() {
      mapboxgl.accessToken = import.meta.env.VITE_MAPBOX_TOKEN
      
      this.map = new mapboxgl.Map({
        container: 'zonzon-map',
        style: 'mapbox://styles/mapbox/satellite-streets-v12',
        projection: 'equalEarth', // Projection qui respecte les vraies tailles
        center: [0, 20],
        zoom: 1.5
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
.zonzon-container {
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
  top: 30px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(0, 0, 0, 0.85);
  padding: 12px 32px;
  border-radius: 8px;
  font-size: 2.2rem;
  font-weight: 700;
  color: #fff;
  box-shadow: 0 2px 8px rgba(0,0,0,0.3);
  z-index: 2;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
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
</style>

.back-button {
  position: absolute;
  top: 20px;
  left: 20px;
  background: #7fa46a;
  color: #fff;
  border: none;
  padding: 18px 36px;
  border-radius: 10px;
  font-size: 2rem;
  font-weight: 700;
  cursor: pointer;
  box-shadow: 0 4px 16px rgba(0,0,0,0.18);
  z-index: 10;
  transition: all 0.3s ease;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

.back-button:hover {
  background: #fff;
  box-shadow: 0 4px 12px rgba(0,0,0,0.2);
  transform: translateY(-2px);
}
