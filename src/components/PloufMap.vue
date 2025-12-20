<template>
  <div class="plouf-map-wrapper">
    <div ref="mapContainer" class="plouf-map"></div>
    <button class="plouf-home-btn" @click="$emit('back')" title="Accueil">Accueil</button>
  </div>
</template>

<script>
import mapboxgl from 'mapbox-gl';
export default {
  name: 'PloufMap',
  mounted() {
    mapboxgl.accessToken = 'pk.eyJ1IjoiZWxpYTY5IiwiYSI6ImNtaWZ1dWxpeDAwNnQzZnF1djVydGZpaWYifQ.gtuX2XSr0O5HV9kDQU1dzA';
    this.map = new mapboxgl.Map({
      container: this.$refs.mapContainer,
      style: 'mapbox://styles/mapbox/satellite-v9',
      center: [2.2137, 46.6034],
      zoom: 4.5
    });
  },
  beforeUnmount() {
    if (this.map) this.map.remove();
  }
}
</script>



<style scoped>
  .plouf-map-wrapper {
    position: relative;
    width: 100vw;
    height: 100vh;
  }
  .plouf-map {
    width: 100vw;
    height: 100vh;
  }
  .plouf-home-btn {
    position: absolute;
    top: 24px;
    left: 24px;
    z-index: 10;
    background: #fff;
    color: #111;
    border: 2px solid #111;
    border-radius: 8px;
    padding: 0.5em 1.2em;
    font-size: 1.2em;
    font-family: inherit;
    cursor: pointer;
    filter: grayscale(1);
    transition: background 0.2s, color 0.2s;
  }
  .plouf-home-btn:hover {
    background: #111;
    color: #fff;
    filter: grayscale(0);
  }
</style>
