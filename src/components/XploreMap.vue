<template>
  <div class="xplore-map-container">
    <div class="map-title">xplore</div>
    <button class="back-btn" @click="$emit('back')">← Accueil</button>
    <button class="reveal-btn" style="display: none;">Révéler Lyon satellite</button>
    <div ref="mapContainer" class="map-container"></div>
  </div>
</template>


<script>
import * as turf from '@turf/turf';
const mapboxgl = window.mapboxgl;
if (!mapboxgl) throw new Error('MapboxGL non disponible (window.mapboxgl)');

// Fonction utilitaire pour créer un polygone cercle GeoJSON (centre [lon, lat], rayon en km)
function createCircle(center, radiusKm, points = 64) {
  const coords = [];
  const [cx, cy] = center;
  const earthRadius = 6371;
  for (let i = 0; i <= points; i++) {
    const angle = (i * 2 * Math.PI) / points;
    const dx = radiusKm * Math.cos(angle);
    const dy = radiusKm * Math.sin(angle);
    // Conversion approximative degrés
    const lat = cy + (dy / earthRadius) * (180 / Math.PI);
    const lon = cx + (dx / earthRadius) * (180 / Math.PI) / Math.cos(cy * Math.PI / 180);
    coords.push([lon, lat]);
  }
  // Sens horaire pour les trous (GeoJSON), déjà OK
  return coords;
}

// Fonction utilitaire pour créer un buffer corridor autour d'un segment [A,B]
function createBufferCorridor(line, bufferKm, steps = 256) {
  const [A, B] = line;
  const left = [], right = [];
  for (let i = 0; i <= steps; i++) {
    const t = i / steps;
    const lon = A[0] + t * (B[0] - A[0]);
    const lat = A[1] + t * (B[1] - A[1]);
    const angle = Math.atan2(B[1] - A[1], B[0] - A[0]);
    const angleLeft = angle - Math.PI / 2;
    const angleRight = angle + Math.PI / 2;
    const dLat = (bufferKm / 6371) * (180 / Math.PI);
    const dLon = dLat / Math.cos(lat * Math.PI / 180);
    left.push([
      lon + dLon * Math.cos(angleLeft),
      lat + dLat * Math.sin(angleLeft)
    ]);
    right.unshift([
      lon + dLon * Math.cos(angleRight),
      lat + dLat * Math.sin(angleRight)
    ]);
  }
  return [...left, ...right, left[0]];
}

// Fonctions utilitaires pour Mapbox
function addSourceIfNotExists(map, id, def) {
  if (!map.getSource(id)) map.addSource(id, def);
}
function addLayerIfNotExists(map, def) {
  if (!map.getLayer(def.id)) map.addLayer(def);
}

export default {
  name: 'XploreMap',
  mounted() {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
    // Génère un suffixe unique pour chaque montage
    const uniqueId = Date.now().toString();
    mapboxgl.accessToken = import.meta.env.VITE_MAPBOX_TOKEN
    this.map = new mapboxgl.Map({
      container: this.$refs.mapContainer,
      style: {
        version: 8,
        sources: {},
        layers: [
          {
            id: 'background',
            type: 'background',
            paint: { 'background-color': '#2196f3' }
          }
        ]
      },
      center: [15, 40], // Méditerranée/Europe
      zoom: 3.5,
      attributionControl: false
    });
    // Ajout de l'échelle cartographique
    this.map.addControl(new mapboxgl.ScaleControl({ maxWidth: 200, unit: 'metric' }), 'bottom-left');

    this.map.on('load', () => {
            // Nettoyage des anciennes couches si elles existent
            ['satellite-corridor-mask-fill','satellite-corridor','land-'+uniqueId,'ocean-'+uniqueId].forEach(id => {
              if (this.map.getLayer(id)) this.map.removeLayer(id);
            });
            ['satellite-corridor-mask','satellite-corridor','land-'+uniqueId,'ocean-'+uniqueId].forEach(id => {
              if (this.map.getSource(id)) this.map.removeSource(id);
            });
      // Vérification de la disponibilité de turf
      const turf = window.turf;
      if (!turf) {
        alert('Turf.js non disponible (window.turf)');
        return;
      }
      // --- Déclaration de toutes les variables en tout début ---
      // IDs dynamiques pour les sources/layers
      const satelliteId = 'satellite-' + uniqueId;
      const satelliteLayerId = 'satellite-couche-' + uniqueId;
      const landId = 'land-' + uniqueId;
      const landLayerId = 'land-' + uniqueId;
      const oceanId = 'ocean-' + uniqueId;
      const oceanLayerId = 'ocean-' + uniqueId;
      const lakesId = 'lakes-' + uniqueId;
      const lakesLayerId = 'lakes-' + uniqueId;
      const coastlineId = 'coastline-' + uniqueId;
      // Ajoute la couche océan (bleu) tout en bas
      addSourceIfNotExists(this.map, oceanId, {
        type: 'geojson',
        data: '/ne_ocean.geojson'
      });
      addLayerIfNotExists(this.map, {
        id: oceanLayerId,
        type: 'fill',
        source: oceanId,
        paint: {
          'fill-color': '#2196f3',
          'fill-opacity': 1
        }
      });

      // --- Ajout des sources et layers dans le bon ordre ---
      // 1. Satellite uniquement dans les buffers (ronds) des villes, au premier plan
      // (plus de masque troué global ni de buffer automatique)
        // (Pas de couche satellite, ni masque, ni debug)

      // (aucun code satellite, base propre)

      // 2. Océan (bleu) tout en bas
      addSourceIfNotExists(this.map, oceanId, {
        type: 'geojson',
        data: '/ne_ocean.geojson'
      });
      addLayerIfNotExists(this.map, {
        id: oceanLayerId,
        type: 'fill',
        source: oceanId,
        paint: {
          'fill-color': '#2196f3',
          'fill-opacity': 1
        }
      });

      // 3. Terre (blanc) au-dessus de l'océan
      // Affiche le trait de côte en blanc
      // Affiche la terre en blanc (remplissage)
      // Charge le trait de côte et génère dynamiquement un polygone terre
      fetch('/ne_coastline.geojson')
        .then(r => r.json())
        .then(coastData => {
          // Fusionne tous les LineString en un seul anneau fermé
          const merged = turf.lineToPolygon(coastData);
          // Ajoute la source polygone terre
           if (!this.map.getSource(landId)) {
             this.map.addSource(landId, {
               type: 'geojson',
               data: merged
             });
           } else {
             this.map.getSource(landId).setData(merged);
           }
           if (!this.map.getLayer(landLayerId)) {
             this.map.addLayer({
               id: landLayerId,
               type: 'fill',
               source: landId,
               paint: {
                 'fill-color': '#fff',
                 'fill-opacity': 1
               },
               beforeId: oceanLayerId // Ajoute la terre juste au-dessus de l’océan
             });
           }
           // Centre la carte sur Marseille
           this.map.setCenter([5.3698, 43.2965]);
           this.map.setZoom(8);
        });
    });
  },
  beforeDestroy() {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  }

}
</script>

<style scoped>

.xplore-map-container {
  background: #2196f3;
}

</style>
