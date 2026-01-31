<template>
  <div class="xplore-map-container">
    <div class="map-title">xplore</div>
    <button class="back-btn" @click="$emit('back')">← Accueil</button>
    <div ref="mapContainer" class="map-container"></div>
      <canvas ref="satCanvas" class="sat-canvas" :width="svgWidth" :height="svgHeight" style="position:absolute;top:0;left:0;pointer-events:none;z-index:20"></canvas>
  </div>
</template>

<script>
import * as turf from '@turf/turf';
import maplibregl from 'maplibre-gl'

function createCircle(center, radiusKm, points = 64) {
  const coords = [];
  const [cx, cy] = center;
  const earthRadius = 6371;
  for (let i = 0; i <= points; i++) {
    const angle = (i * 2 * Math.PI) / points;
    const dx = radiusKm * Math.cos(angle);
    const dy = radiusKm * Math.sin(angle);
    const lat = cy + (dy / earthRadius) * (180 / Math.PI);
    const lon = cx + (dx / earthRadius) * (180 / Math.PI) / Math.cos(cy * Math.PI / 180);
    coords.push([lon, lat]);
  }
  return coords;
}

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

function addSourceIfNotExists(map, id, def) {
  if (!map.getSource(id)) map.addSource(id, def);
}
function addLayerIfNotExists(map, def) {
  if (!map.getLayer(def.id)) map.addLayer(def);
}

export default {
  name: 'XploreMap',
  data() {
    return {
      svgWidth: 0,
      svgHeight: 0,
      circles: []
    }
  },
  mounted() {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
    const uniqueId = Date.now().toString();
    const satelliteId = 'satellite-' + uniqueId;
    const satelliteLayerId = 'satellite-couche-' + uniqueId;
    const landId = 'land-' + uniqueId;
    const landLayerId = 'land-' + uniqueId;
    const oceanId = 'ocean-' + uniqueId;
    const oceanLayerId = 'ocean-' + uniqueId;
    const lakesId = 'lakes-' + uniqueId;
    const lakesLayerId = 'lakes-' + uniqueId;
    const coastlineId = 'coastline-' + uniqueId;
    const bufferId = `satellite-buffer-marseille-${uniqueId}`;
    const bufferLayerId = `satellite-buffer-layer-marseille-${uniqueId}`;
    const rasterId = `satellite-raster-marseille-${uniqueId}`;

    this.map = new maplibregl.Map({
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
      center: [5.3698, 43.2965],
      zoom: 8,
      attributionControl: false
    });
    this.map.addControl(new maplibregl.ScaleControl({ maxWidth: 200, unit: 'metric' }), 'bottom-left');

      this.map.on('load', async () => {
        const turf = window.turf;
        if (!turf) {
          alert('Turf.js non disponible (window.turf)');
          return;
        }
        const marseilleCenter = [5.3698, 43.2965];
        const radius = 25;
        const circle = turf.circle(marseilleCenter, radius, { steps: 128, units: 'kilometers' });
        addSourceIfNotExists(this.map, bufferId, {
          type: 'geojson',
          data: circle
        });
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

        const coastResp = await fetch('/ne_coastline.geojson');
        const coastData = await coastResp.json();
        let merged = turf.lineToPolygon(coastData);

        let landWithHole = merged;
        if (merged.geometry.type === 'Polygon') {
          const holeRing = circle.geometry.coordinates[0];
          const exterior = merged.geometry.coordinates[0];
          const otherHoles = merged.geometry.coordinates.slice(1);
          landWithHole.geometry.coordinates = [exterior, holeRing, ...otherHoles];
        } else if (merged.geometry.type === 'MultiPolygon') {
          const holeRing = circle.geometry.coordinates[0];
          const firstPolyExterior = merged.geometry.coordinates[0][0];
          const firstPolyHoles = merged.geometry.coordinates[0].slice(1);
          merged.geometry.coordinates[0] = [firstPolyExterior, holeRing, ...firstPolyHoles];
        }

        if (!this.map.getSource(landId)) {
          this.map.addSource(landId, {
            type: 'geojson',
            data: landWithHole
          });
        } else {
          this.map.getSource(landId).setData(landWithHole);
        }

        addSourceIfNotExists(this.map, rasterId, {
          type: 'raster',
          tiles: [
            'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
          ],
          tileSize: 256
        });

        if (!this.map.getLayer(rasterId)) {
          this.map.addLayer({
            id: rasterId,
            type: 'raster',
            source: rasterId,
            paint: {
              'raster-opacity': 0.85
            }
          });
        }
        if (!this.map.getLayer(landLayerId)) {
          this.map.addLayer({
            id: landLayerId,
            type: 'fill',
            source: landId,
            paint: {
              'fill-color': '#fff',
              'fill-opacity': 1
            }
          }, rasterId);
        }
      });
  }

}
</script>

<style scoped>
.sat-overlay {
  position: absolute;
  top: 0;
  left: 0;
  pointer-events: none;
  z-index: 20;
}
.sat-canvas {
  position: absolute;
  top: 0;
  left: 0;
  pointer-events: none;
  z-index: 20;
}

.xplore-map-container {
  background: #2196f3;
  position: relative;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
}

.map-title {
  position: absolute;
  top: 24px;
  left: 50%;
  transform: translateX(-50%);
  font-size: 1.2rem;
  font-weight: bold;
  color: #222;
  background: #fff;
  padding: 0.3em 1.2em;
  border-radius: 1.5em;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  z-index: 10;
  letter-spacing: 0.1em;
}

.back-btn {
  position: absolute;
  top: 24px;
  left: 24px;
  font-size: 1.1rem;
  background: #fff;
  color: #2196f3;
  border: none;
  border-radius: 1em;
  padding: 0.5em 1.2em;
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  cursor: pointer;
  z-index: 11;
  transition: background 0.2s, color 0.2s;
}
.back-btn:hover {
  background: #2196f3;
  color: #fff;
}

.map-container {
  position: absolute;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  z-index: 1;
}

</style>
