        // DEBUG : Afficher le buffer en contour rouge pour vérifier qu'il est bien généré
        this.map.addLayer({
          id: 'trajet-buffer-outline',
          type: 'line',
          source: 'trajet-buffer',
          paint: {
            'line-color': '#d00',
            'line-width': 2
          }
        });
<template>
  <div class="plouf-map-wrapper">
    <div ref="mapContainer" class="plouf-map"></div>
    <button class="plouf-home-btn" @click="$emit('back')" title="Accueil">Accueil</button>
  </div>
</template>


<script>
import mapboxgl from 'mapbox-gl';
import * as turf from '@turf/turf';

export default {
  name: 'PloufMap',
  mounted() {
    mapboxgl.accessToken = 'pk.eyJ1IjoiZWxpYTY5IiwiYSI6ImNtaWZ1dWxpeDAwNnQzZnF1djVydGZpaWYifQ.gtuX2XSr0O5HV9kDQU1dzA'; // Remplace par ta clé Mapbox

    this.map = new mapboxgl.Map({
      container: this.$refs.mapContainer,
      style: 'mapbox://styles/mapbox/satellite-v9',
      center: [2.2137, 46.6034],
      zoom: 4.5
    });

    this.map.on('load', async () => {
      // 1. Créer les cercles Paris et Lyon
      const paris = [2.3522, 48.8566];
      const lyon = [4.8357, 45.7640];
      const circleParis = turf.circle(paris, 10, { steps: 64, units: 'kilometers' });
      const circleLyon = turf.circle(lyon, 10, { steps: 64, units: 'kilometers' });

      // 2. Récupérer le tracé Paris-Lyon via Mapbox Directions API
      const directionsUrl = `https://api.mapbox.com/directions/v5/mapbox/driving/${paris.join(',')};${lyon.join(',')}?geometries=geojson&access_token=${mapboxgl.accessToken}`;
      const response = await fetch(directionsUrl);
      const data = await response.json();
      const route = data.routes[0].geometry;
      // 3. Buffer de 50km autour du trajet
      const buffer = turf.buffer(route, 50, { units: 'kilometers' });

      // 4. Créer un polygone monde avec trous (Paris, Lyon, buffer)
      const world = turf.polygon([[[-180, -85], [180, -85], [180, 85], [-180, 85], [-180, -85]]]);
      const mask = turf.difference(
        world,
        turf.union(circleParis, circleLyon, buffer)
      );

      // 5. Ajouter la source et la couche de masque blanc
      if (this.map.getSource('mask')) this.map.removeSource('mask');
      if (this.map.getLayer('mask-white')) this.map.removeLayer('mask-white');
      this.map.addSource('mask', {
        type: 'geojson',
        data: mask
      });
      this.map.addLayer({
        id: 'mask-white',
        type: 'fill',
        source: 'mask',
        paint: {
          'fill-color': '#fff',
          'fill-opacity': 1
        }
      });

      // 6. Ajouter le tracé du trajet
      if (this.map.getSource('trajet')) this.map.removeSource('trajet');
      if (this.map.getLayer('trajet-line')) this.map.removeLayer('trajet-line');
      this.map.addSource('trajet', {
        type: 'geojson',
        data: route
      });
      this.map.addLayer({
        id: 'trajet-line',
        type: 'line',
        source: 'trajet',
        paint: {
          'line-color': '#222',
          'line-width': 3
        }
      });
    });

    // Ajout de l'échelle
    this.map.on('load', () => {
      // ...existing code...
      // Ajout de l'échelle
      const scale = new mapboxgl.ScaleControl({ maxWidth: 200, unit: 'metric' });
      this.map.addControl(scale);
    });

    this.map.on('load', () => {
      const style = this.map.getStyle();
      // Masquer toutes les couches sauf les traits de côtes, rivières, fleuves
      style.layers.forEach(layer => {
        // On garde uniquement les layers de type 'line' liés à l'eau ou aux rivières
        const keep =
          (layer.type === 'line' &&
            (
              layer['source-layer'] === 'water' ||
              layer['source-layer'] === 'waterway' // rivières, fleuves
            )
          );
        // On masque tout le reste (y compris les toponymes, routes, etc.)
        if (!keep) {
          this.map.setLayoutProperty(layer.id, 'visibility', 'none');
        }
      });
      // Ajout d'un contour noir sur les littoraux (si pas déjà visible)
      if (!this.map.getLayer('coastline-black')) {
        this.map.addLayer({
          id: 'coastline-black',
          type: 'line',
          source: 'composite',
          'source-layer': 'water',
          paint: {
            'line-color': '#111',
            'line-width': 1.2
          }
        });
      }
      // Mettre les rivières/fleuves en noir aussi
      if (this.map.getLayer('waterway')) {
        this.map.setPaintProperty('waterway', 'line-color', '#111');
        this.map.setPaintProperty('waterway', 'line-width', 1);
      }
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
