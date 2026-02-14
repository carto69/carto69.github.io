<template>
  <div class="zonzon-container">
    <button class="back-button" @click="$emit('back')" title="Retour à l'accueil">Accueil</button>
    <div id="zonzon-map" class="map-canvas"></div>

    <div class="map-title">Statitistiques carcérales mondiales (2022 - 2026)</div>

    <div class="legend" v-if="selectedIndicator">
      <div class="legend-title">{{ currentIndicatorName() }}</div>
      <div class="legend-scale">
        <template v-if="['population_prison','nb_etablissements'].includes(selectedIndicator)">
          <div v-for="item in getCircleLegendData()" :key="item.max" class="legend-circle-item">
            <div class="legend-circle-wrapper">
              <span class="legend-circle"
                :style="{
                  width: item.radius * 2 + 'px',
                  height: item.radius * 2 + 'px',
                  backgroundColor: selectedIndicator === 'nb_etablissements' ? '#b53c0a' : '#000',
                  border: 'none'
                }"
              ></span>
            </div>
            <span class="legend-label-right">
              {{ new Intl.NumberFormat('fr-FR').format(item.min) }} - {{ new Intl.NumberFormat('fr-FR').format(item.max) }}
            </span>
          </div>
        </template>
        <template v-else>
          <div v-for="(color, i) in getLegendColors()" :key="i" class="legend-item">
            <span class="legend-color" :style="{ backgroundColor: color }"></span>
            <span class="legend-label">{{ getLegendLabel(i) }}</span> 
          </div>
        </template>
        <div class="legend-item legend-nodata" style="display: flex; align-items: center; margin-top: 8px;">
          <span class="legend-color" style="background-color: #000; margin-right: 8px;"></span>
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
        { id: 'nb_etablissements', name: "Nombre d'établissements", unit: '' },
        { id: 'taux_pour_100k', name: 'Population carcérale pour 100 000 habitant.es', unit: '' },
        { id: 'taux_occupation', name: 'Taux d\'occupation moyen', unit: '%' },
        { id: 'attente_jugement', name: 'Part des détentions provisoires', unit: '%' },
        { id: 'femmes', name: 'Part des détenues', unit: '%' },
        { id: 'etrangers', name: 'Part des étranger.es ', unit: '%' },
        { id: 'part_mineurs_detenus', name: 'Part des mineur.es', unit: '%' }
      ],
      colorSchemes: {
          part_mineurs_detenus: ['#fbeee6', '#f5c6b8', '#e89c7a', '#d96f3a', '#b53c0a', '#7a1c00'],
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
              const breaks = this.computeQuantileBreaks(indicator, colors.length)
              if (!colors || colors.length < 2 || !breaks || breaks.length === 0) {
                return [
                  'case',
                  ['==', ['get', 'has_data'], false], '#000',
                  '#000'
                ]
              }
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
          const breaks = this.computeQuantileBreaks(indicator, colors ? colors.length : 6)
          const n = colors ? colors.length : 6
          const isPercent = ['taux_occupation', 'attente_jugement', 'femmes', 'etrangers', 'part_mineurs_detenus'].includes(indicator)
          const unit = isPercent ? ' %' : ''
          if (!breaks || breaks.length === 0) return 'donnée manquante';
          if (index === 0) {
            const val = breaks[0] !== undefined ? breaks[0].toFixed(1) : 'N/A';
            return isPercent && val !== 'donnée manquante' && val !== 'N/A' ? `0 - ${val} %` : `0 - ${val}`;
          } else if (index < n - 1) {
            const prev = breaks[index - 1];
            const next = breaks[index];
            const prevVal = prev !== undefined ? prev.toFixed(1) : 'donnée manquante';
            const nextVal = next !== undefined ? next.toFixed(1) : 'donnée manquante';
            if (prev === undefined || next === undefined) return 'donnée manquante';
            return isPercent && prevVal !== 'donnée manquante' && nextVal !== 'donnée manquante' ? `${prevVal} - ${nextVal} %` : `${prevVal} - ${nextVal}`;
          } else {
            const prev = breaks[n - 2];
            const prevVal = prev !== undefined ? prev.toFixed(1) : 'donnée manquante';
            if (prev === undefined) return 'donnée manquante';
            return isPercent && prevVal !== 'donnée manquante' ? `${prevVal}+ %` : `${prevVal}+`;
          }
        },
        getCircleLegendData() {
          if (!this.geoData) return []
          let indicator = this.selectedIndicator
          if (["population_prison","nb_etablissements"].includes(indicator)) {
            const radii = [2.5, 5, 8, 11, 16, 25];
            const values = this.geoData.features
              .filter(f => f.properties[indicator] && f.properties[indicator] > 0)
              .map(f => f.properties[indicator])
              .sort((a, b) => a - b)
            if (values.length === 0) return []
            const n = values.length
            const classes = 6
            const breaks = []
            for (let i = 0; i <= classes; i++) {
              const p = i / classes
              const idx = Math.floor(p * (n - 1))
              breaks.push(values[idx])
            }
            const legend = []
            for (let i = 0; i < classes; i++) {
              legend.push({
                min: Math.round(breaks[i]),
                max: Math.round(breaks[i + 1]),
                radius: radii[i]
              })
            }
            return legend
          } else {
            return []
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
    async loadData() {
      try {
        const csvResponse = await fetch('/conditionscarcéralesparpays.csv')
        const csv = await csvResponse.text()
        const Papa = (await import('papaparse')).default
        const parsed = Papa.parse(csv, { header: true, skipEmptyLines: true })
        const csvByIso = {}
        parsed.data.forEach(row => {
          if (row['iso3']) csvByIso[row['iso3'].trim().toUpperCase()] = row
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
            const num = v => {
              if (v === '' || v === 'N/A' || v == null) return null;
              if (typeof v === 'string') v = v.replace(',', '.');
              const n = Number(v);
              return isNaN(n) ? null : n;
            }
            let pdm_active = csvRow ? csvRow.pdm_active : null;
            let pdm_active_date = null;
            if (pdm_active && pdm_active.toLowerCase().startsWith('non')) {
              const match = pdm_active.match(/\(([^)]+)\)/);
              pdm_active_date = match ? match[1] : null;
              pdm_active = 'Non';
            } else if (pdm_active && pdm_active.toLowerCase() === 'oui') {
              pdm_active = 'Oui';
            }
            if (csvRow) {
              const pop = num(csvRow['pop_carcerale']);
              f.properties = {
                ...f.properties,
                id: csvRow['id'],
                name: csvRow['pays'],
                capitale: csvRow['capitale'],
                population_prison: pop,
                taux_pour_100k: num(csvRow['pop_carcerale_100000hab']),
                taux_occupation: num(csvRow['tx_occup']),
                attente_jugement: num(csvRow['part_detenus_attente_jugement']),
                femmes: num(csvRow['part_femmes_detenues']),
                etrangers: num(csvRow['part_detenus_etrangers']),
                population: num(csvRow['pop_nat_2023']),
                idh: num(csvRow['idh']),
                nb_etablissements: num(csvRow['nb_etablissements']),
                part_mineurs_detenus: num(csvRow['part_mineurs_detenus']),
                age_minimal: (csvRow['age_minimal'] && csvRow['age_minimal'] !== 'N/A') ? Number(csvRow['age_minimal']) : null,
                stock_mineur_detenus: (csvRow['stock_mineur_detenus'] && csvRow['stock_mineur_detenus'] !== 'N/A') ? Number(csvRow['stock_mineur_detenus'].replace(',', '.')) : null,
                pdm_active: pdm_active,
                pdm_active_date: pdm_active_date,
                ISO_A3: csvRow['iso3'],
                ISO_A2: csvRow['iso2'],
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
        center: [20, 20],
        zoom: 1.3,
        maxZoom: 8,
        attributionControl: true
      })
      this.map.on('load', () => {
        this.setupLayers()
        this.map.on('click', 'prison-fill', this.handlePolygonClick)
        const observer = new MutationObserver(() => {
          const attrib = document.querySelector('.maplibregl-ctrl-attrib.maplibregl-ctrl-attrib-expanded .maplibregl-ctrl-attrib-inner');
          if (attrib) attrib.innerHTML = 'Carto ; MapLibre ; OSM';
        });
        observer.observe(document.body, { subtree: true, attributes: true, attributeFilter: ['class'] });
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
            'circle-stroke-width': 0,
            'circle-radius': [
              'interpolate',
              ['linear'],
              ['get', 'population_prison'],
              0, 1,
              500, 3,
              1000, 6,
              2500, 9,
              10000, 12,
              100000, 15,
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
      if (indicator === 'population_prison' || indicator === 'nb_etablissements') {
        this.map.setPaintProperty('prison-fill', 'fill-color', [
          'case',
          ['==', ['get', 'has_data'], false], '#000',
          'rgba(0,0,0,0)'
        ])
        if (indicator === 'nb_etablissements') {
          this.map.setPaintProperty('prison-circles', 'circle-color', '#b53c0a')
        } else {
          this.map.setPaintProperty('prison-circles', 'circle-color', '#000')
        }
        const features = this.geoData.features.filter(f => f.properties[indicator] && f.properties[indicator] > 0)
        const values = features.map(f => f.properties[indicator]).sort((a, b) => a - b)
        const classes = 6
        const radii = [2.5, 5, 8, 11, 16, 25]
        let circleExpr = [
          "case",
          ["==", ["get", "has_data"], false], 0.1,
          ["interpolate", ["linear"], ["zoom"],
            0.7,
            ["step", ["get", indicator], radii[0]*0.08,
              ...(() => {
                if (values.length === 0) return [];
                const n = values.length;
                const breaks = [];
                for (let i = 1; i < classes; i++) {
                  const p = i / classes;
                  const idx = Math.floor(p * (n - 1));
                  breaks.push(values[idx]);
                }
                let arr = [];
                for (let i = 0; i < breaks.length; i++) {
                  arr.push(breaks[i], radii[i + 1]*0.08);
                }
                return arr;
              })()
            ],
            3,
            ["step", ["get", indicator], radii[0],
              ...(() => {
                if (values.length === 0) return [];
                const n = values.length;
                const breaks = [];
                for (let i = 1; i < classes; i++) {
                  const p = i / classes;
                  const idx = Math.floor(p * (n - 1));
                  breaks.push(values[idx]);
                }
                let arr = [];
                for (let i = 0; i < breaks.length; i++) {
                  arr.push(breaks[i], radii[i + 1]);
                }
                return arr;
              })()
            ],
            6,
            ["step", ["get", indicator], radii[0]*6,
              ...(() => {
                if (values.length === 0) return [];
                const n = values.length;
                const breaks = [];
                for (let i = 1; i < classes; i++) {
                  const p = i / classes;
                  const idx = Math.floor(p * (n - 1));
                  breaks.push(values[idx]);
                }
                let arr = [];
                for (let i = 0; i < breaks.length; i++) {
                  arr.push(breaks[i], radii[i + 1]*6);
                }
                return arr;
              })()
            ]
          ]
        ];
        this.map.setPaintProperty('prison-circles', 'circle-radius', circleExpr);
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
      let html = `<div style="background:white;border:2.5px solid #111;border-radius:8px;padding:6px;min-width:380px;max-width:600px;font-family:'Space Grotesk',sans-serif;color:#111;box-shadow:none;margin:0;white-space:normal;overflow-wrap:break-word;">
        <div style="display:flex;justify-content:space-between;align-items:center;font-size:1.1em;white-space:nowrap;margin-bottom:2px;">
          <span style="text-align:left;font-weight:1000;">${props.name || ''}</span>
          <span style="text-align:right;font-weight:600;margin-left:18px;">${props.capitale && props.capitale !== 'N/A' ? props.capitale : 'donnée manquante  '}</span>
        </div>
        <div style="margin-top:4px;white-space:nowrap;"><span style='color:#111;font-weight:bold;'>Population</span> : ${props.population && props.population !== 'N/A' ? new Intl.NumberFormat('fr-FR').format(props.population) + ' habitant.es' : 'donnée manquante'}</div>
        <div style="margin-top:4px;white-space:nowrap;"><span style='color:#111;font-weight:bold;'>Population carcérale</span> : ${props.population_prison && props.population_prison !== 'N/A' ? new Intl.NumberFormat('fr-FR').format(props.population_prison) + ' détenu.es' : 'donnée manquante'}</div>
        <div style="display:flex;justify-content:space-between;margin-top:4px;white-space:nowrap;">
          <span style="text-align:left;"><span style='color:#111;font-weight:bold;'>Peine de mort</span> : ${props.pdm_active === 'Oui' ? 'active' : (props.pdm_active === 'Non' && props.pdm_active_date ? 'abolie en ' + props.pdm_active_date : (props.pdm_active === 'Non' ? 'abolie' : 'donnée manquante'))}</span>
          <span style="text-align:right;"><span style='color:#111;font-weight:bold;'>IDH</span> : ${props.idh && props.idh !== 'N/A' ? props.idh : 'donnée manquante'}</span>
        </div>
        ${indicator !== 'population_prison' ? `<div style="margin-top:4px;white-space:nowrap;"><span style='color:#111;font-weight:bold;'>${indicatorLabel}</span> : ${(indicatorValue !== undefined && indicatorValue !== null && indicatorValue !== 'N/A') ? new Intl.NumberFormat('fr-FR').format(indicatorValue) + (indicatorUnit && indicatorValue !== 'donnée manquante' ? ' ' + indicatorUnit : '') : 'donnée manquante'}</div>` : ''}
        ${indicator === 'part_mineurs_detenus' ? `<div style="margin-top:4px;white-space:nowrap;">Age minimal de détention : ${props.age_minimal && props.age_minimal !== 'N/A' ? props.age_minimal + ' ans' : 'donnée manquante'}</div>
        <div style="margin-top:4px;white-space:nowrap;">Nombre de mineurs détenus : ${props.stock_mineur_detenus && props.stock_mineur_detenus !== 'N/A' ? new Intl.NumberFormat('fr-FR').format(props.stock_mineur_detenus) : 'donnée manquante'}</div>` : ''}
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
  bottom: 15px;
  left: 15px;
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
  height: 40px;
}

.legend-circle-wrapper {
  width: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.legend-label-right {
  min-width: 80px;
  text-align: left;
  display: flex;
  align-items: center;
  height: 40px;
}

.legend-circle-wrapper {
  width: 40px;
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
  display: inline-block;
  min-width: 8px;
  min-height: 8px;
  border: none;
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


.zonzon-container, .zonzon-container * {
  font-family: 'Courier 10 Pitch', 'Courier New', Courier, monospace !important;
}
</style>
