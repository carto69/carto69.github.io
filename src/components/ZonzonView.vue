<template>
  <div class="zonzon-container">
    <button class="back-button" @click="$emit('back')" title="Retour à l'accueil">Accueil</button>
    <div id="zonzon-map" class="map-canvas"></div>

    <div class="map-title">Statitistiques carcérales mondiales (2022 - 2026)</div>

    <div class="legend" v-if="selectedIndicator">
      <div class="legend-title">{{ currentIndicatorName() }}</div>
      <div class="legend-scale" v-if="selectedIndicator !== 'population_prison'">
        <div v-for="(color, i) in getLegendColors()" :key="i" class="legend-item">
          <span class="legend-color" :style="{ backgroundColor: color }"></span>
          <span class="legend-label">{{ getLegendLabel(i) }}</span> 
        </div>
        <div class="legend-item legend-nodata">
          <span class="legend-color" style="background-color: #000" ></span>
          <span class="legend-label">Pays sans données disponibles</span>
        </div>
      </div>
      <div class="legend-scale legend-scale-circles" v-else>
        <div v-for="item in getCircleLegendData()" :key="item.max" class="legend-circle-item">
          <div class="legend-circle-wrapper">
            <span class="legend-circle" :style="{ width: item.radius * 2 + 'px', height: item.radius * 2 + 'px' }"></span>
          </div>
          <span class="legend-label-right">
            {{ new Intl.NumberFormat('fr-FR').format(item.min) }} - {{ new Intl.NumberFormat('fr-FR').format(item.max) }}
          </span>
        </div>
        <div class="legend-item legend-nodata" style="margin-top: 8px;">
          <span class="legend-color" style="background-color: #000"></span>
          <span class="legend-label">Pays sans données disponibles</span>
        </div>
      </div>
      <div class="legend-source">
        Source : World Prison Brief<br>
      </div>
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
import maplibregl from 'maplibre-gl';

export default {
  name: 'ZonzonMap',
  data() {
    return {
      selectedIndicator: 'population_prison',
      indicators: [
        { id: 'population_prison', name: 'Population carcérale', unit: 'détenus' },
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
      map: null,
      geoData: null,
      capitals: {},
      centroidData: null,
      layerAdded: false,
      popup: null,
      showLegendInfo: false
    }
  },
  mounted() {
    this.initMap()
    this.loadData()
    document.addEventListener('click', this.handleMapClickOutside)
  },
  beforeUnmount() {
    if (this.map) {
      this.map.remove()
    }
    document.removeEventListener('click', this.handleMapClickOutside)
  },
  methods: {
                buildCentroidCollection() {
                  if (!this.geoData) return { type: 'FeatureCollection', features: [] }
                  const features = this.geoData.features
                    .filter(f => f.properties.population_prison && f.properties.population_prison > 0)
                    .filter(f => {
                      const iso = (f.properties.ISO_A3 || '').trim().toUpperCase()
                      const name = (f.properties.ADMIN || f.properties.name || '').trim().toUpperCase()
                      return iso !== 'ATA' && name !== 'ANTARCTICA'
                    })
                    .map(f => {
                      let coords = null
                      if (f.geometry.type === 'Polygon') {
                        const ringsRaw = f.geometry.coordinates
                        if (!Array.isArray(ringsRaw) || !ringsRaw.length) {
                          console.warn('Polygon sans coordonnées:', f.properties.name)
                          return null
                        }
                        const rings = ringsRaw.filter(r => Array.isArray(r) && r.length > 0)
                        if (!rings.length) {
                          console.warn('Polygon vide:', f.properties.name)
                          return null
                        }
                        let ring = rings[0]
                        for (let r of rings) {
                          if (Array.isArray(r) && r.length > ring.length) ring = r
                        }
                        if (!Array.isArray(ring) || !ring.length) {
                          console.warn('Anneau vide:', f.properties.name)
                          return null
                        }
                        try {
                          coords = ring.reduce((acc, cur) => {
                            if (!Array.isArray(cur) || cur.length < 2) {
                              console.warn('Coordonnée non valide dans ring:', f.properties.name, cur)
                              return acc
                            }
                            return [acc[0] + cur[0], acc[1] + cur[1]]
                          }, [0, 0])
                          coords = [coords[0] / ring.length, coords[1] / ring.length]
                        } catch (e) {
                          console.warn('Erreur reduce Polygon:', f.properties.name, e)
                          return null
                        }
                      } else if (f.geometry.type === 'MultiPolygon') {
                        const polysRaw = f.geometry.coordinates
                        if (!Array.isArray(polysRaw) || !polysRaw.length) {
                          console.warn('MultiPolygon sans coordonnées:', f.properties.name)
                          return null
                        }
                        const polys = polysRaw.filter(p => Array.isArray(p) && p.length > 0)
                        if (!polys.length) {
                          console.warn('MultiPolygon vide:', f.properties.name)
                          return null
                        }
                        let poly = polys[0]
                        for (let p of polys) {
                          if (Array.isArray(p[0]) && p[0].length > poly[0].length) poly = p
                        }
                        const ring = Array.isArray(poly[0]) ? poly[0] : poly
                        if (!Array.isArray(ring) || !ring.length) {
                          console.warn('Anneau MultiPolygon vide:', f.properties.name)
                          return null
                        }
                        try {
                          coords = ring.reduce((acc, cur) => {
                            if (!Array.isArray(cur) || cur.length < 2) {
                              console.warn('Coordonnée non valide dans ring MultiPolygon:', f.properties.name, cur)
                              return acc
                            }
                            return [acc[0] + cur[0], acc[1] + cur[1]]
                          }, [0, 0])
                          coords = [coords[0] / ring.length, coords[1] / ring.length]
                        } catch (e) {
                          console.warn('Erreur reduce MultiPolygon:', f.properties.name, e)
                          return null
                        }
                      }
                      if (!coords || coords.some(c => typeof c !== 'number' || isNaN(c))) {
                        console.warn('Coordonnées invalides:', f.properties.name, coords)
                        return null
                      }
                      return {
                        type: 'Feature',
                        geometry: { type: 'Point', coordinates: coords },
                        properties: {
                          ...f.properties
                        }
                      }
                    })
                    .filter(f => f && f.geometry && Array.isArray(f.geometry.coordinates) && f.geometry.coordinates.every(c => typeof c === 'number' && !isNaN(c)));
  return { type: 'FeatureCollection', features }
                },
            getFillColorExpression() {
              const indicator = this.selectedIndicator
              if (!this.geoData || !this.colorSchemes[indicator]) return '#222'
              const colors = this.colorSchemes[indicator]
              const breaks = this.computeQuantileBreaks(indicator, 6)
              const expr = ['step', ['get', indicator], colors[0]]
              for (let i = 0; i < breaks.length; i++) {
                expr.push(breaks[i], colors[i+1] || colors[colors.length-1])
              }
              return [
                'case',
                ['==', ['get', 'has_data'], false], '#000',
                expr
              ]
            },
        currentIndicatorName() {
          return this.indicators.find(i => i.id === this.selectedIndicator)?.name || ''
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
          const breaks = []
          const classes = 6
          for (let i = 0; i <= classes; i++) {
            const p = i / classes
            const idx = Math.floor(p * (n - 1))
            breaks.push(values[idx])
          }
          const radii = [4, 6, 8, 10, 12, 14]
          const legend = []
          for (let i = 0; i < classes; i++) {
            legend.push({
              min: Math.round(breaks[i]),
              max: Math.round(breaks[i + 1]),
              radius: radii[i]
            })
          }
          return legend
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
    async loadData() {
      try {
        const csvResponse = await fetch('/conditionscarcéralesparpays.csv')
        const csv = await csvResponse.text()
        const Papa = (await import('papaparse')).default
        const parsed = Papa.parse(csv, { header: true, skipEmptyLines: true })
        const csvByIso = {}
        parsed.data.forEach(row => {
          if (row['Code_ISO3']) csvByIso[row['Code_ISO3'].trim().toUpperCase()] = row
        })

        const geojsonResponse = await fetch('/world-boundaries.geojson')
        let worldGeo = null
        try {
          worldGeo = await geojsonResponse.json()
        } catch (e) {
          console.error('Erreur parsing GeoJSON:', e)
          return
        }
        if (!worldGeo || !worldGeo.features) {
          console.error('GeoJSON non valide ou features manquantes')
          return
        }

        const features = worldGeo.features
          .filter(f => f.geometry && (f.geometry.type === 'Polygon' || f.geometry.type === 'MultiPolygon') && f.geometry.coordinates)
          .filter(f => {
            const iso = (f.properties.ISO_A3 || '').trim().toUpperCase()
            const name = (f.properties.ADMIN || f.properties.name || '').trim().toUpperCase()
            return iso !== 'ATA' && name !== 'ANTARCTICA'
          })
          .map(f => {
            let iso = (f.properties.ISO_A3 || '').trim().toUpperCase()
            const csvRow = csvByIso[iso]
            const num = v => (v === '' || v === 'N/A' || v == null) ? null : Number(v)
            if (csvRow) {
              const pop = num(csvRow['Population carcerale totale'])
              f.properties = {
                ...f.properties,
                id: csvRow.ID,
                name: csvRow['Pays / Nations'],
                capitale: csvRow.capitale,
                population_prison: pop,
                taux_pour_100k: num(csvRow['Population carcerale pour 100 000 habitants']),
                taux_occupation: num(csvRow["Taux d'occupation (%)"]),
                attente_jugement: num(csvRow["Detenus en attente de jugement (%)"]),
                femmes: num(csvRow["Femmes detenues (%)"]),
                etrangers: num(csvRow["Prisonniers Eİtrangers (%)"]),
                population: num(csvRow['Population_2023']),
                ISO_A3: csvRow['Code_ISO3'],
                ISO_A2: csvRow['Code_ISO2'],
                has_data: pop > 0
              }
            } else {
              f.properties = {
                ...f.properties,
                has_data: false
              }
            }
            return f
          })
        const featuresSansAntarctique = features.filter(f => {
          const iso = (f.properties.ISO_A3 || '').trim().toUpperCase()
          const name = (f.properties.ADMIN || f.properties.name || '').trim().toUpperCase()
          return iso !== 'ATA' && name !== 'ANTARCTICA'
        })
        this.geoData = { type: 'FeatureCollection', features: featuresSansAntarctique }
        this.capitals = {}
        features.forEach(f => {
          if (f.properties.ISO_A3 && f.properties.capitale) {
            this.capitals[f.properties.ISO_A3] = f.properties.capitale
          }
        })
        this.centroidData = this.buildCentroidCollection()
        this.setupLayers()
      } catch (error) {
        console.error('Erreur chargement/parsing CSV ou GeoJSON:', error)
      }
    },
    initMap() {
      this.map = new maplibregl.Map({
        container: 'zonzon-map',
        style: 'https://basemaps.cartocdn.com/gl/voyager-nolabels-gl-style/style.json',
        projection: 'naturalEarth',
        center: [15, 30],
        zoom: 0.7,
        maxZoom: 8
      })
      this.map.on('load', () => {
        this.setupLayers()
        this.map.on('click', 'prison-fill', this.handlePolygonClick)
      })
      const scaleControl = new maplibregl.ScaleControl({
        maxWidth: 100,
        unit: 'metric'
      })
      this.map.addControl(scaleControl, 'top-right')
      const navControl = new maplibregl.NavigationControl()
      this.map.addControl(navControl, 'top-right')
    },
    setupLayers() {
      if (!this.geoData || !this.map) return
      const filteredFeatures = this.geoData.features.filter(f => {
        const iso = (f.properties.ISO_A3 || '').trim().toUpperCase()
        const name = (f.properties.ADMIN || f.properties.name || '').trim().toUpperCase()
        return iso !== 'ATA' && name !== 'ANTARCTICA'
      })
      const filteredGeoData = { type: 'FeatureCollection', features: filteredFeatures }
      const filteredCentroids = this.centroidData && this.centroidData.features ?
        { type: 'FeatureCollection', features: this.centroidData.features.filter(f => {
          const iso = (f.properties.ISO_A3 || '').trim().toUpperCase()
          const name = (f.properties.ADMIN || f.properties.name || '').trim().toUpperCase()
          return iso !== 'ATA' && name !== 'ANTARCTICA'
        }) } : this.centroidData
      if (!this.map.getSource('prison-data')) {
        this.map.addSource('prison-data', {
          type: 'geojson',
          data: filteredGeoData
        })
      } else {
        this.map.getSource('prison-data').setData(filteredGeoData)
      }
      if (!this.map.getSource('prison-centroids')) {
        this.map.addSource('prison-centroids', {
          type: 'geojson',
          data: filteredCentroids
        })
      } else {
        this.map.getSource('prison-centroids').setData(filteredCentroids)
      }

      if (!this.map.getLayer('prison-fill')) {
        this.map.addLayer({
          id: 'prison-fill',
          type: 'fill',
          source: 'prison-data',
          paint: {
            'fill-color': '#ccc',
            'fill-opacity': 0.85,
            'fill-outline-color': '#222'
          }
        })
      }
      if (!this.map.getLayer('prison-circles')) {
        this.map.addLayer({
          id: 'prison-circles',
          type: 'circle',
          source: 'prison-centroids',
          paint: {
            'circle-color': '#000',
            'circle-opacity': 0.7,
            'circle-stroke-color': '#fff',
            'circle-stroke-width': 1,
            'circle-radius': [
              'interpolate',
              ['linear'],
              ['get', 'population_prison'],
              0, 0.5,
              100, 1,
              1000, 2,
              5000, 3,
              20000, 4.5,
              100000, 6
            ]
          }
        })
      }
      this.layerAdded = true
      this.applyIndicatorStyles()
    },
    applyIndicatorStyles() {
      if (!this.map || !this.layerAdded) return
      const indicator = this.selectedIndicator
      if (indicator === 'population_prison') {
        this.map.setPaintProperty('prison-fill', 'fill-color', [
          'case',
          ['==', ['get', 'has_data'], false], '#000',
          'rgba(0,0,0,0)'
        ])
        if (this.map.getLayer('prison-circles')) {
          this.map.setLayoutProperty('prison-circles', 'visibility', 'visible')
        }
      } else {
        if (this.getFillColorExpression) {
          const fillColor = this.getFillColorExpression()
          this.map.setPaintProperty('prison-fill', 'fill-color', fillColor)
        }
        if (this.map.getLayer('prison-circles')) {
          this.map.setLayoutProperty('prison-circles', 'visibility', 'none')
        }
      }
    },

    onIndicatorChange() {
      this.applyIndicatorStyles()
    },
    handlePolygonClick(e) {
      if (!e.features || !e.features.length) return
      const f = e.features[0]
      const props = f.properties
      const indicator = this.selectedIndicator
      const indicatorValue = props[indicator]
      const indicatorObj = this.indicators.find(i => i.id === indicator)
      const indicatorLabel = indicatorObj ? indicatorObj.name : indicator
      const indicatorUnit = indicatorObj ? indicatorObj.unit : ''
      let html = `<div style="background:white;border:2.5px solid #111;border-radius:8px;padding:6px;width:350px;font-family:'Space Grotesk',sans-serif;color:#111;box-shadow:none;margin:0;white-space:nowrap;overflow-wrap:normal;">
        <div style="font-weight:700;font-size:1.1em;white-space:nowrap;">${props.name || ''}</div>
        <div style="margin-top:4px;white-space:nowrap;">Capitale : ${props.capitale && props.capitale !== 'N/A' ? props.capitale : 'Donnée inconnue'}</div>
        <div style="margin-top:4px;white-space:nowrap;">Population : ${props.population && props.population !== 'N/A' ? new Intl.NumberFormat('fr-FR').format(props.population) + ' habitant.es' : 'Données inconnues'}</div>
        <div style="margin-top:4px;white-space:nowrap;">Population carcérale : ${props.population_prison && props.population_prison !== 'N/A' ? new Intl.NumberFormat('fr-FR').format(props.population_prison) + ' détenu.es' : 'Données inconnues'}</div>
        ${indicator !== 'population_prison' ? `<div style="margin-top:4px;white-space:nowrap;">${indicatorLabel} : ${(indicatorValue !== undefined && indicatorValue !== null && indicatorValue !== 'N/A') ? new Intl.NumberFormat('fr-FR').format(indicatorValue) : 'Données inconnues'}${indicatorUnit}</div>` : ''}
      </div>`
      if (this.popup) {
        this.popup.remove()
        this.popup = null
      }
      const lngLat = e.lngLat
      this.popup = new maplibregl.Popup({closeButton:false, closeOnClick:false})
        .setLngLat(lngLat)
        .setHTML(html)
        .addTo(this.map)
      e.originalEvent.stopPropagation()
    },
    handleMapClickOutside(e) {
      if (this.popup) {
        const popupEl = document.querySelector('.maplibregl-popup')
        if (popupEl && !popupEl.contains(e.target)) {
          this.popup.remove()
          this.popup = null
        }
      }
    }
  },
  beforeUnmount() {
    if (this.map) {
      this.map.remove()
    }
    document.removeEventListener('click', this.handleMapClickOutside)
  }
}
</script>

<style scoped>
.legend-credit {
  display: block;
  margin-top: 8px;
  font-size: 11px;
  color: #888;
  line-height: 0.7;
}

.zonzon-container {
  position: relative;
  width: 100%;
  height: 100vh;
  background: #000;
  font-family: 'Courier 10 Pitch', 'Courier New', Courier, monospace;
}

.map-canvas {
  width: 100%;
  height: 100%;
}

.map-title {
  position: absolute;
  top: 10px;
  left: 50%;
  transform: translateX(-50%);
  background: #fff;
  color: #111;
  font-family: 'Courier 10 Pitch', 'Courier New', Courier, monospace;
  border: 1px solid #111;
  padding: 5px 14px;
  border-radius: 8px;
  font-size: 1.2rem;
  font-weight: 700;
  box-shadow: 0 2px 6px rgba(0,0,0,0.18);
  z-index: 2;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

.indicator-selector {
  position: absolute;
  left: 50%;
  bottom: 10px;
  transform: translateX(-50%);
  background: #fff;
  padding: 8px 12px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  gap: 8px;
  z-index: 4;
  box-shadow: 0 3px 10px rgba(0,0,0,0.22);
  border: 1px solid #111;
}

.indicator-selector label {
  color: #111;
  font-size: 12px;
  font-weight: 700;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

.indicator-selector select {
  background: #fff;
  color: #111;
  border: 1px solid #111;
  padding: 6px 8px;
  border-radius: 8px;
  font-size: 12px;
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
  padding: 5px 10px;
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
  bottom: 10px;
  left: 10px;
  background: #fff;
  border: 1px solid #111;
  border-radius: 8px;
  padding: 10px 10px;
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

.legend-circle-item {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 12px;
  color: #333;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
  height: 29px;
}

.legend-circle-wrapper {
  width: 30px;
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
  background-color: #000000;
  border-radius: 50%;
  flex-shrink: 0;
  min-width: 12px;
  min-height: 12px;
  display: inline-block;
  min-width: 8px;
  min-height: 8px;
}

.legend-label {
  flex-grow: 1;
}

.legend-label-right {
  min-width: 80px;
  text-align: left;
}

:deep(.maplibregl-popup-close-button) {
  color: #111;
  font-size: 20px;
}

:deep(.maplibregl-ctrl-scale) {
  background-color: rgba(255, 255, 255, 0.9);
  width: auto;
  border: 2px solid #333;
  border-top: none;
  font-size: 12px;
  font-weight: 600;
  padding: 4px 8px;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

:deep(.maplibregl-ctrl-top-right) {
  display: flex;
  flex-direction: row;
  align-items: flex-start;
  gap: 8px;
}

:deep(.maplibregl-ctrl-top-right .maplibregl-ctrl-scale) {
  order: 0;
  margin-right: 0;
  top: 10px;
}

:deep(.maplibregl-ctrl-top-right .maplibregl-ctrl-group) {
  order: 1;
}
.zonzon-container, .zonzon-container * {
  font-family: 'Courier 10 Pitch', 'Courier New', Courier, monospace !important;
}
</style>
