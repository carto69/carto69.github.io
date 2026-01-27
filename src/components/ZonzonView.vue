<template>
  <div class="zonzon-container">
    <button class="back-button" @click="$emit('back')" title="Retour à l'accueil">← Accueil</button>
    <div id="zonzon-map" class="map-canvas"></div>
    
    <div class="map-title">Statitistiques carcérales sur les États</div>
    
    <div class="legend" v-if="selectedIndicator">
      <div class="legend-title">{{ currentIndicatorName() }}</div>
      <div class="legend-scale" v-if="selectedIndicator !== 'population_prison'">
        <div v-for="(color, i) in getLegendColors()" :key="i" class="legend-item">
          <span class="legend-color" :style="{ backgroundColor: color }"></span>
          <span class="legend-label">{{ getLegendLabel(i) }}</span>
        </div>
        <div class="legend-item legend-nodata">
          <span class="legend-color" style="backgroundColor: #000"></span>
          <span class="legend-label">Pays sans données disponibles</span>
        </div>
      </div>
      <div class="legend-scale legend-scale-circles" v-else>
        <div v-for="item in getCircleLegendData()" :key="item.value" class="legend-circle-item">
          <div class="legend-circle-wrapper">
            <span class="legend-circle" :style="{ width: item.radius * 2 + 'px', height: item.radius * 2 + 'px' }"></span>
          </div>
          <span class="legend-label-right">{{ new Intl.NumberFormat('fr-FR').format(item.value) }}</span>
        </div>
        <div class="legend-item legend-nodata" style="margin-top: 8px;">
          <span class="legend-color" style="backgroundColor: #000"></span>
          <span class="legend-label">Pays sans données disponibles</span>
        </div>
      </div>
      <div class="legend-source">Sources : World Prison Brief 2020 - 2023</div>
    </div>
    
    <div class="indicator-selector" v-if="indicators.length > 0">
      <label for="indicator-select">Indicateur:</label>
      <select 
        id="indicator-select" 
        v-model="selectedIndicator"
        @change="onIndicatorChange"
      >
        <option v-for="indicator in indicators" :key="indicator.id" :value="indicator.id">
          {{ indicator.name }}
        </option>
      </select>
    </div>
    
  </div>
</template>

<script>
import maplibregl from 'maplibre-gl'
import * as turf from '@turf/turf'

export default {
  name: 'ZonzonView',
  data() {
    return {
      map: null,
      geoData: null,
      centroidData: null,
      capitalCoords: {},
      capitals: {},
      popup: null,
      selectedIndicator: 'population_prison',
      indicators: [
        { id: 'population_prison', name: 'Population carcérale totale', unit: 'détenus' },
        { id: 'taux_pour_100k', name: 'Population carcérale pour 100 000 habitants', unit: '' },
        { id: 'taux_occupation', name: 'Taux d\'occupation moyen', unit: '%' },
        { id: 'attente_jugement', name: 'Part des détenus en attente de jugement', unit: '%' },
        { id: 'femmes', name: 'Part des femmes détenues', unit: '%' },
        { id: 'etrangers', name: 'Part des prisonniers étrangers', unit: '%' }
      ],
      colorSchemes: {
        taux_pour_100k: ['#f3e5f5', '#e1bee7', '#ce93d8', '#ba68c8', '#9c27b0', '#6a1b9a'],
        taux_occupation: ['#ffeede', '#f9d6b3', '#f3b97c', '#eb9841', '#d96f00', '#9c4c00'],
        attente_jugement: ['#e7f0ff', '#c8dcff', '#9fc1ff', '#6fa0ff', '#3b7ae6', '#1f4fa3'],
        femmes: ['#e6f6ea', '#c5e9cf', '#9dd6ae', '#6cbf87', '#3ea964', '#1f7a45'],
        etrangers: ['#ffe9e9', '#ffc7c7', '#ff9b9b', '#ff6c6c', '#e63b3b', '#b71c1c']
      },
      layerAdded: false
    }
  },
  mounted() {
    this.initMap()
    this.loadData()
  },
  methods: {
    initMap() {
      this.map = new maplibregl.Map({
        container: 'zonzon-map',
        style: 'https://basemaps.cartocdn.com/gl/voyager-nolabels-gl-style/style.json',
        projection: 'globe',
        center: [15, 30],
        zoom: 1.3,
        maxZoom: 8
      })

      this.map.on('load', () => {
        this.setupLayers()
      })

      const navControl = new maplibregl.NavigationControl()
      this.map.addControl(navControl, 'top-right')
      
      const scaleControl = new maplibregl.ScaleControl({ 
        maxWidth: 200,
        unit: 'metric' 
      })
      this.map.addControl(scaleControl, 'bottom-left')
    },

    async loadData() {
      try {
        const response = await fetch('/zonzon/world-prison-data.geojson')
        this.geoData = await response.json()
        this.normalizeProperties()
      } catch (error) {
        console.error('Erreur chargement données:', error)
      }

      try {
        const response = await fetch('/zonzon/capital-coords.json')
        this.capitalCoords = await response.json()
        this.centroidData = this.buildCentroidCollection()
      } catch (error) {
        console.error('Erreur chargement coordonnées capitales:', error)
        this.centroidData = this.buildCentroidCollection()
      }
    },

    setupLayers() {
      if (!this.geoData) {
        setTimeout(() => this.setupLayers(), 500)
        return
      }

      if (!this.map.getSource('prison-data')) {
        this.map.addSource('prison-data', {
          type: 'geojson',
          data: this.geoData
        })
      }

      const centroidCollection = this.centroidData || this.buildCentroidCollection()
      if (!this.map.getSource('prison-centroids')) {
        this.map.addSource('prison-centroids', {
          type: 'geojson',
          data: centroidCollection
        })
      }

      if (!this.map.getLayer('prison-fill')) {
        this.map.addLayer({
          id: 'prison-fill',
          type: 'fill',
          source: 'prison-data',
          paint: {
            'fill-color': '#222',
            'fill-opacity': [
              'case',
              ['feature-state', 'hover'],
              0.85,
              0.65
            ]
          }
        })

        this.map.addLayer({
          id: 'prison-line',
          type: 'line',
          source: 'prison-data',
          paint: {
            'line-color': '#999',
            'line-width': 0.3,
            'line-opacity': 0.4
          }
        })

        this.map.addLayer({
          id: 'prison-circle',
          type: 'circle',
          source: 'prison-centroids',
          layout: {
            visibility: 'none'
          },
          paint: {
            'circle-radius': this.getCircleRadiusExpression(),
            'circle-color': ['case', ['==', ['get', 'population_prison'], null], '#666', '#000'],
            'circle-opacity': ['case', ['==', ['get', 'population_prison'], null], 0.3, 0.7],
            'circle-stroke-width': 0
          }
        }),

        this.layerAdded = true

        this.map.on('mousemove', 'prison-fill', (e) => {
          if (e.features.length > 0) {
            const feature = e.features[0]
            this.map.setFeatureState(
              { source: 'prison-data', id: feature.id },
              { hover: true }
            )
          }
        })

        this.map.on('mouseleave', 'prison-fill', () => {
          this.map.querySourceFeatures('prison-data').forEach(feature => {
            this.map.setFeatureState(
              { source: 'prison-data', id: feature.id },
              { hover: false }
            )
          })
        })

        this.map.on('click', 'prison-fill', (e) => {
          if (e.features.length > 0) {
            const feature = e.features[0]
            const coords = e.lngLat
            this.showPopup(coords, feature.properties)
          }
        })

        this.map.on('click', 'prison-circle', (e) => {
          if (e.features.length > 0) {
            const feature = e.features[0]
            const coords = feature.geometry.coordinates
            this.showPopup({ lng: coords[0], lat: coords[1] }, feature.properties)
          }
        })

        this.applyIndicatorStyles()
      }
    },

    normalizeProperties() {
      if (!this.geoData) return
      const numericKeys = ['population_prison', 'taux_pour_100k', 'taux_occupation', 'attente_jugement', 'femmes', 'etrangers']
      this.geoData.features = this.geoData.features
        .filter(f => {
          const name = f.properties.name || f.properties.NAME || ''
          const iso = f.properties.ISO_A3 || ''
          const geom = f.geometry
          if (name === 'Baikonur' || name === 'Antarctica' || iso === 'ATA') return false
          if (!geom || !geom.coordinates) return false
          if (geom.type === 'Point' && geom.coordinates.some(c => !Number.isFinite(c))) return false
          return true
        })
        .map(f => {
          const props = { ...f.properties }
          numericKeys.forEach(k => {
            const v = props[k]
            if (v === null || v === undefined || v === 'N/A' || v === 'null') {
              props[k] = null
            } else {
              const num = Number(v)
              props[k] = Number.isFinite(num) ? num : null
            }
          })
          f.properties = props
          return f
        })
    },

    buildCentroidCollection() {
      if (!this.geoData) return null
      const features = this.geoData.features
        .filter(f => {
          const name = f.properties.name || f.properties.NAME || ''
          const iso = f.properties.ISO_A3 || ''
          return name !== 'Baikonur' && name !== 'Antarctica' && iso !== 'ATA'
        })
        .map(f => {
          const nameToISO3 = {
            'France': 'FRA',
            'Norway': 'NOR'
          }
          
          let iso3 = f.properties.ISO_A3
          const name = f.properties.name || f.properties.NAME || ''
          
          if (iso3 === '-99' || !iso3) {
            iso3 = nameToISO3[name] || iso3
          }
          
          let coords = this.capitalCoords[iso3] || this.computeCentroidOfFeature(f)
          
          return {
            type: 'Feature',
            geometry: {
              type: 'Point',
              coordinates: coords
            },
            properties: f.properties
          }
        })
      return { type: 'FeatureCollection', features }
    },

    computeCentroidOfFeature(feature) {
      const specialCentroids = {
        'USA': [-95.7129, 37.0902],
        'États-Unis': [-95.7129, 37.0902],
        'Russia': [105, 60],
        'Россия': [105, 60],
        'Canada': [-95, 60],
        'France': [2.3522, 48.8566],
        'Netherlands': [4.90, 52.37],
        'Pays-Bas': [4.90, 52.37]
      }
      
      const name = feature.properties.name || feature.properties.NAME || ''
      if (specialCentroids[name]) {
        return specialCentroids[name]
      }
      
      try {
        const centroid = turf.centroid(feature)
        return centroid.geometry.coordinates
      } catch (e) {
        const geom = feature.geometry
        const coords = geom?.coordinates
        if (!geom || !coords) return [0, 0]

        const accumulate = (arr) => {
          let sumX = 0, sumY = 0, n = 0
          arr.forEach(pt => {
            sumX += pt[0]
            sumY += pt[1]
            n += 1
          })
          return n ? [sumX / n, sumY / n] : [0, 0]
        }

        if (geom.type === 'Point') return coords
        if (geom.type === 'MultiPoint') return accumulate(coords)
        if (geom.type === 'LineString') return accumulate(coords)
        if (geom.type === 'MultiLineString') return accumulate(coords.flat())
        if (geom.type === 'Polygon') return accumulate(coords[0])
        if (geom.type === 'MultiPolygon') return accumulate(coords.flat(2))
        return [0, 0]
      }
    },

    computeQuantileBreaks(indicator, classes = 6) {
      if (!this.geoData) return []
      const values = this.geoData.features
        .map(f => f.properties[indicator])
        .filter(v => typeof v === 'number' && Number.isFinite(v))
        .sort((a, b) => a - b)
      if (values.length === 0) return []
      const breaks = []
      for (let i = 1; i < classes; i++) {
        const p = i / classes
        const idx = Math.floor(p * values.length)
        breaks.push(values[Math.min(idx, values.length - 1)])
      }
      return breaks
    },

    getFillColorExpression() {
      const indicator = this.selectedIndicator
      const colors = this.colorSchemes[indicator]
      if (!colors || colors.length < 2) {
        return ['case', ['==', ['get', 'has_data'], false], '#000', '#888']
      }

      const breaks = this.computeQuantileBreaks(indicator, colors.length)
      const stepParts = ['step', ['get', indicator], colors[0]]
      breaks.forEach((brk, i) => {
        const threshold = Number.isFinite(brk) ? brk : 0
        stepParts.push(threshold, colors[Math.min(i + 1, colors.length - 1)])
      })

      return [
        'case',
        ['==', ['get', indicator], null], '#000',
        ['==', ['get', 'has_data'], false], '#000',
        stepParts
      ]
    },

    getCircleRadiusExpression() {
      const indicator = 'population_prison'
      if (!this.geoData) return 6
      let min = Infinity
      let max = 0
      this.geoData.features.forEach(f => {
        const v = f.properties[indicator]
        if (typeof v === 'number' && v > 0 && Number.isFinite(v)) {
          if (v < min) min = v
          if (v > max) max = v
        }
      })
      if (!Number.isFinite(min) || !Number.isFinite(max) || min === Infinity || max === 0) {
        return 6
      }
      return [
        'case',
        ['==', ['get', indicator], null], 0,
        ['interpolate', ['linear'], ['sqrt', ['get', indicator]],
          Math.sqrt(min), 3,
          Math.sqrt(max), 28
        ]
      ]
    },

    getLegendColors() {
      const indicator = this.selectedIndicator
      return this.colorSchemes[indicator] || []
    },

    getLegendLabel(index) {
      if (!this.geoData) return ''
      const indicator = this.selectedIndicator
      const colors = this.colorSchemes[indicator]
      const breaks = this.computeQuantileBreaks(indicator, colors.length)
      const n = colors.length
      const isPercent = ['taux_occupation', 'attente_jugement', 'femmes', 'etrangers'].includes(indicator)
      const unit = isPercent ? ' %' : ''
      if (index === 0) {
        return `0 - ${breaks[0] ? breaks[0].toFixed(1) : 'N/A'}${unit}`
      } else if (index < n - 1) {
        const prev = breaks[index - 1]
        const next = breaks[index]
        return `${prev.toFixed(1)} - ${next.toFixed(1)}${unit}`
      } else {
        const prev = breaks[n - 2]
        return `${prev.toFixed(1)}+${unit}`
      }
    },

    getCircleLegendData() {
      if (!this.geoData || this.selectedIndicator !== 'population_prison') return []
      const values = this.geoData.features
        .filter(f => f.properties.population_prison && f.properties.population_prison > 0)
        .map(f => f.properties.population_prison)
        .sort((a, b) => a - b)
      
      if (values.length === 0) return []
      
      const n = values.length
      const getQuantileValue = (q) => {
        const idx = Math.floor(q * (n - 1))
        return values[idx]
      }
      
      const quantiles = [
        getQuantileValue(0),
        getQuantileValue(1/6),
        getQuantileValue(2/6),
        getQuantileValue(3/6),
        getQuantileValue(4/6),
        getQuantileValue(5/6)
      ]
      
      const radii = [3, 6, 10, 15, 21, 28]
      
      const legend = quantiles.map((val, i) => ({
        value: Math.round(val),
        radius: radii[i]
      }))
      
      return legend
    },

    currentIndicatorName() {
      return this.indicators.find(i => i.id === this.selectedIndicator)?.name || ''
    },

    showPopup(coords, properties) {
      if (!this.popup) {
        this.popup = new maplibregl.Popup({
          closeButton: true,
          closeOnClick: false,
          anchor: 'bottom'
        })
      }

      const nameToISO3 = {
        'France': 'FRA',
        'Norway': 'NOR'
      }
      
      let iso3 = properties.ISO_A3
      const name = properties.name || properties.NAME || ''
      
      if (iso3 === '-99' || !iso3) {
        iso3 = nameToISO3[name] || iso3
      }
      
      const capital = this.capitals[iso3] || 'N/A'
      const indicatorVal = properties[this.selectedIndicator]
      const indicatorName = this.indicators.find(i => i.id === this.selectedIndicator)?.name || 'N/A'
      
      const popFormatter = (num) => new Intl.NumberFormat('fr-FR').format(num)
      
      let html = '<div style="font-family: Space Grotesk, sans-serif; font-size: 13px; color: #111; line-height: 1.5;">'
      html += '<div style="font-weight: 700; font-size: 14px; margin-bottom: 8px; border-bottom: 1px solid #ddd; padding-bottom: 6px;">'
      html += (properties.name || properties.NAME || 'Pays inconnu') + '</div>'
      html += '<div style="margin-bottom: 4px;"><strong>Capitale : </strong> ' + capital + '</div>'
      html += '<div style="margin-bottom: 4px;"><strong>Population : </strong> ' + (properties.population ? popFormatter(properties.population) : 'N/A') + '</div>'
      html += '<div style="margin-bottom: 4px;"><strong>Population carcérale : </strong> ' + (properties.population_prison ? popFormatter(properties.population_prison) : 'N/A') + '</div>'
      html += '<div style="margin-top: 8px; padding-top: 8px; border-top: 1px solid #ddd;">'
      html += '<strong>' + indicatorName + ' : </strong> ' + (indicatorVal !== null && indicatorVal !== undefined ? indicatorVal.toFixed(1) : 'N/A')
      html += '</div></div>'

      this.popup
        .setLngLat(coords)
        .setHTML(html)
        .addTo(this.map)
    },

    applyIndicatorStyles() {
      if (!this.map || !this.layerAdded) return
      const indicator = this.selectedIndicator

      if (indicator === 'population_prison') {
        this.map.setLayoutProperty('prison-circle', 'visibility', 'visible')
        this.map.setPaintProperty('prison-circle', 'circle-radius', this.getCircleRadiusExpression())
        this.map.setPaintProperty('prison-fill', 'fill-color', [
          'case',
          ['==', ['get', 'has_data'], false], '#000',
          'rgba(0,0,0,0)'
        ])
      } else {
        this.map.setLayoutProperty('prison-circle', 'visibility', 'none')
        const fillColor = this.getFillColorExpression()
        this.map.setPaintProperty('prison-fill', 'fill-color', fillColor)
      }
    },

    onIndicatorChange() {
      if (this.map && this.map.isStyleLoaded() && this.layerAdded) {
        this.applyIndicatorStyles()
      }
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
  top: 22px;
  left: 50%;
  transform: translateX(-50%);
  background: #fff;
  color: #111;
  border: 1px solid #111;
  padding: 8px 18px;
  border-radius: 8px;
  font-size: 1.2rem;
  font-weight: 700;
  box-shadow: 0 2px 6px rgba(0,0,0,0.18);
  z-index: 2;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

.indicator-selector {
  position: absolute;
  top: 18px;
  right: 85px;
  background: #fff;
  padding: 12px 18px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  gap: 12px;
  z-index: 2;
  box-shadow: 0 3px 10px rgba(0,0,0,0.22);
  border: 1px solid #111;
}

.indicator-selector label {
  color: #111;
  font-size: 15px;
  font-weight: 700;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

.indicator-selector select {
  background: #fff;
  color: #111;
  border: 1px solid #111;
  padding: 9px 12px;
  border-radius: 8px;
  font-size: 15px;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
  cursor: pointer;
  transition: all 0.15s ease;
}

.indicator-selector select:hover {
  background: #f6f6f6;
}

.indicator-selector select:focus {
  outline: none;
  box-shadow: 0 0 0 2px rgba(0,0,0,0.2);
}

.indicator-selector select option {
  background: #fff;
  color: #111;
}

.back-button {
  position: absolute;
  top: 12px;
  left: 12px;
  background: #fff;
  color: #111;
  border: 1px solid #111;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.16);
  z-index: 10;
  transition: all 0.2s ease;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

.back-button:hover {
  background: #f4f4f4;
  box-shadow: 0 3px 10px rgba(0,0,0,0.18);
  transform: translateY(-1px);
}

.legend {
  position: absolute;
  bottom: 16px;
  left: 16px;
  background: #fff;
  border: 1px solid #111;
  border-radius: 8px;
  padding: 12px 14px;
  z-index: 3;
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
  max-width: 200px;
}

.legend-title {
  font-size: 13px;
  font-weight: 700;
  color: #111;
  margin-bottom: 10px;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
  border-bottom: 1px solid #ddd;
  padding-bottom: 8px;
}

.legend-source {
  font-size: 10px;
  color: #666;
  margin-top: 10px;
  padding-top: 8px;
  border-top: 1px solid #ddd;
  font-style: italic;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

.legend-scale {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.legend-scale-circles {
  gap: 2px;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #333;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

.legend-nodata {
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px solid #ddd;
}

.legend-circle-item {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 12px;
  color: #333;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
  height: 60px;
}

.legend-circle-wrapper {
  width: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.legend-color {
  width: 16px;
  height: 16px;
  border: 0.5px solid #999;
  border-radius: 2px;
  flex-shrink: 0;
}

.legend-circle {
  background-color: #000;
  border: 0.5px solid #666;
  border-radius: 50%;
  flex-shrink: 0;
  display: inline-block;
}

.legend-label {
  flex-grow: 1;
}

.legend-label-right {
  min-width: 80px;
  text-align: left;
}

:deep(.maplibregl-popup) {
  max-width: none;
  width: auto;
}

:deep(.maplibregl-popup-content) {
  background: #fff;
  border-radius: 8px;
  border: 1px solid #111;
  box-shadow: 0 2px 10px rgba(0,0,0,0.2);
  padding: 14px;
  white-space: normal;
  word-wrap: break-word;
  overflow: visible;
  min-width: 340px;
}

:deep(.maplibregl-popup-close-button) {
  color: #111;
  font-size: 20px;
}

:deep(.maplibregl-popup-close-button:hover) {
  background-color: #f0f0f0;
}

:deep(.maplibregl-ctrl-scale) {
  background-color: rgba(255, 255, 255, 0.9);
  border: 2px solid #333;
  border-top: none;
  font-size: 14px;
  font-weight: 600;
  padding: 4px 8px;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

:deep(.maplibregl-ctrl-bottom-left) {
  position: absolute;
  bottom: 22px;
  left: 280px;
  pointer-events: none;
}

:deep(.maplibregl-ctrl-bottom-left .maplibregl-ctrl) {
  margin: 0;
}
</style>
