<template>
  <div class="dashboard-r">
    <button class="back-btn" @click="$emit('back')">← Retour</button>

    <div class="layout" :class="{ 'sidebar-collapsed': sidebarCollapsed }">
      <aside class="sidebar">
        <div class="sidebar-header">
          <h4>Analyse COMOVE</h4>
          <p>Quais des Bateliers (Strasbourg)</p>
          <button class="toggle" @click="sidebarCollapsed = !sidebarCollapsed" aria-label="Basculer le menu">
            ☰
          </button>
        </div>
        <nav>
          <button v-for="tab in tabs" :key="tab.key" :class="['nav-item', { active: activeTab === tab.key }]" @click="activeTab = tab.key">
            <span v-html="tab.label"></span>
          </button>
        </nav>
      </aside>

      <main class="content">
        <header class="content-header">
          <div>
            <h3>Dashboard interactif</h3>
            <p>Elia Terragni – M1 Carthagéo – Université Paris Cité</p>
          </div>
        </header>

        <section v-if="state.error" class="error-box">{{ state.error }}</section>

        <section v-else>
          <section v-show="activeTab === 'carte'" class="panel">
            <div class="map-wrapper">
              <div ref="carteContainer" class="map"></div>
              <div class="floating-box title-box">
                <h4>Situation du Quai des Bateliers (Strasbourg)</h4>
                <p class="sources">Sources : Strasbourg Open Data, OSM, IGN, Mobiliscope — discrétisation en quantiles</p>
              </div>
              <div class="floating-box legend" v-if="legends.carte.labels.length">
                <div class="legend-title">Part d'actifs</div>
                <div class="legend-items">
                  <div v-for="(label, idx) in legends.carte.labels" :key="label" class="legend-item">
                    <span class="color" :style="{ background: legends.carte.colors[idx] }"></span>
                    <span>{{ label }}</span>
                  </div>
                </div>
                <div class="legend-title">Population</div>
                <div class="legend-circles">
                  <div v-for="(label, idx) in legends.carte.popLabels" :key="label" class="legend-item">
                    <span class="circle" :style="circleStyle(idx)"></span>
                    <span>{{ label }}</span>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section v-show="activeTab === 'mobilites'" class="panel">
            <div class="map-wrapper">
              <div class="controls">
                <label for="anneeRange">Année de mise en service</label>
                <input
                  id="anneeRange"
                  v-model.number="filters.annee"
                  type="range"
                  :min="state.minYear || 2015"
                  :max="state.maxYear || 2025"
                  :step="1"
                />
                <span class="value">{{ filters.annee }}</span>
              </div>
              <div ref="mobilitesContainer" class="map"></div>
              <div class="floating-box title-box">
                <h4>Réseau cyclable de Strasbourg</h4>
                <p class="sources">Sources : Strasbourg Open Data, OpenStreetMap — aménagements sans date affichés par défaut</p>
              </div>
              <div class="floating-box legend" v-if="legends.mobilites.amenagements.length">
                <div class="legend-title">Aménagements cyclables</div>
                <div class="legend-items columns">
                  <div v-for="item in legends.mobilites.amenagements" :key="item.label" class="legend-item">
                    <span class="color" :style="{ background: item.color }"></span>
                    <span>{{ item.label }}</span>
                  </div>
                </div>
                <div class="legend-title">Stations VELHOP</div>
                <div class="legend-item">
                  <span class="station"></span>
                  <span>Vélos libre-service</span>
                </div>
                <div class="legend-title">Trafic</div>
                <div class="legend-item" v-for="niveau in legends.mobilites.trafic" :key="niveau.label">
                  <span class="line" :style="{ height: niveau.width + 'px' }"></span>
                  <span>{{ niveau.label }}</span>
                </div>
              </div>
            </div>
          </section>

          <section v-show="activeTab === 'temporelle'" class="panel charts">
            <div class="chart-header">
              <div>
                <h4>Analyse temporelle des déplacements</h4>
                <p>8h–19h — pourcentage par heure</p>
              </div>
              <select v-model="filters.tempCategory">
                <option value="motif">Motif de déplacement</option>
                <option value="transport">Mode de transport</option>
                <option value="age">Classe d'âge</option>
                <option value="genre">Genre</option>
              </select>
            </div>
            <canvas ref="tempChart"></canvas>
          </section>

          <section v-show="activeTab === 'ressenti'" class="panel charts grid">
            <div class="chart-card">
              <div class="chart-header">
                <h4>Ressenti par mode de transport</h4>
                <select v-model="filters.ressentiMode">
                  <option value="Sentiment_securite">Sentiment de sécurité</option>
                  <option value="Perception_risque_collision_pietons_cyclistes">Risque de collision</option>
                  <option value="Perception_tensions">Perception des tensions</option>
                </select>
              </div>
              <canvas ref="bubbleMode"></canvas>
            </div>
            <div class="chart-card">
              <div class="chart-header">
                <h4>Ressenti par genre</h4>
                <select v-model="filters.ressentiGenre">
                  <option value="Sentiment_securite">Sentiment de sécurité</option>
                  <option value="Perception_risque_collision_pietons_cyclistes">Risque de collision</option>
                  <option value="Perception_tensions">Perception des tensions</option>
                </select>
              </div>
              <canvas ref="bubbleGenre"></canvas>
            </div>
            <div class="chart-card">
              <div class="chart-header">
                <h4>Ressenti par fréquence</h4>
                <select v-model="filters.ressentiFrequence">
                  <option value="Sentiment_securite">Sentiment de sécurité</option>
                  <option value="Perception_risque_collision_pietons_cyclistes">Risque de collision</option>
                  <option value="Perception_tensions">Perception des tensions</option>
                </select>
              </div>
              <canvas ref="bubbleFrequence"></canvas>
            </div>
            <div class="chart-card">
              <div class="chart-header">
                <h4>Ressenti par classe d'âge</h4>
                <select v-model="filters.ressentiAge">
                  <option value="Sentiment_securite">Sentiment de sécurité</option>
                  <option value="Perception_risque_collision_pietons_cyclistes">Risque de collision</option>
                  <option value="Perception_tensions">Perception des tensions</option>
                </select>
              </div>
              <canvas ref="bubbleAge"></canvas>
            </div>
          </section>

          <section v-show="activeTab === 'stats'" class="panel charts grid">
            <div class="chart-card">
              <div class="chart-header">
                <h4>Camembert</h4>
                <select v-model="filters.camembert">
                  <option value="Genre">Genre</option>
                  <option value="Classe_age">Âge</option>
                  <option value="Mode_transport">Mode de transport</option>
                </select>
              </div>
              <canvas ref="pieChart"></canvas>
            </div>
            <div class="chart-card">
              <h4>Modes par âge</h4>
              <canvas ref="barAge"></canvas>
            </div>
            <div class="chart-card">
              <h4>Modes par genre</h4>
              <canvas ref="barGenre"></canvas>
            </div>
          </section>

          <section v-show="activeTab === 'donnees'" class="panel info">
            <div class="info-content">
              <h3>Source des données</h3>
              <div class="source-box" v-for="item in dataSources" :key="item.title">
                <p><strong>{{ item.title }}</strong> {{ item.text }}</p>
                <div class="link">{{ item.link }}</div>
              </div>

              <h3>Références techniques</h3>
              <ul class="refs">
                <li>R, Shiny, shinydashboard</li>
                <li>Leaflet, ggplot2, sf, dplyr</li>
              </ul>
            </div>
          </section>
        </section>
      </main>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'
import Chart from 'chart.js/auto'
import Papa from 'papaparse'

const tabs = [
  { key: 'carte', label: 'Situation Strasbourg' },
  { key: 'mobilites', label: 'Réseau cyclable' },
  { key: 'temporelle', label: 'Analyse temporelle' },
  { key: 'ressenti', label: 'Ressentis' },
  { key: 'stats', label: 'Statistiques' },
  { key: 'donnees', label: 'Données' }
]

const sidebarCollapsed = ref(false)
const activeTab = ref('carte')

const carteContainer = ref(null)
const mobilitesContainer = ref(null)

const tempChart = ref(null)
const bubbleMode = ref(null)
const bubbleGenre = ref(null)
const bubbleFrequence = ref(null)
const bubbleAge = ref(null)
const pieChart = ref(null)
const barAge = ref(null)
const barGenre = ref(null)

const chartInstances = new Map()
let carteMap = null
let mobilitesMap = null
let quaiMarkerCarte = null
let quaiMarkerMob = null

const state = reactive({
  loading: true,
  error: null,
  districts: [],
  districtsGeoJSON: null,
  districtsCenters: [],
  stations: [],
  amgCycl: [],
  fluxVoies: null,
  enquete: [],
  occupation: [],
  population: [],
  minYear: null,
  maxYear: null
})

const filters = reactive({
  annee: null,
  tempCategory: 'motif',
  camembert: 'Genre',
  ressentiMode: 'Sentiment_securite',
  ressentiGenre: 'Perception_risque_collision_pietons_cyclistes',
  ressentiFrequence: 'Perception_tensions',
  ressentiAge: 'Sentiment_securite'
})

const legends = reactive({
  carte: { colors: [], labels: [], popSizes: [], popLabels: [], breaks: [], popBreaks: [] },
  mobilites: { amenagements: [], trafic: [
    { label: 'Faible', width: 2 },
    { label: 'Moyen', width: 4 },
    { label: 'Élevé', width: 6 }
  ] }
})

const dataSources = [
  { title: 'Enquête Co-Move', text: 'Enquête sur la conciliation des mobilités actives.', link: 'https://anr.fr/Projet-ANR-23-SARP-0012' },
  { title: 'Réseau routier', text: 'Flux de trafic à Strasbourg.', link: 'https://data.strasbourg.eu/explore/dataset/sirac_flux_trafic/information/' },
  { title: 'Aménagements cyclables', text: 'Réseau cyclable de la ville de Strasbourg.', link: 'https://data.strasbourg.eu/explore/dataset/amg_cycl_bnac/map/' },
  { title: 'Stations VELHOP', text: 'Stations vélos en libre-service.', link: 'https://data.strasbourg.eu/explore/dataset/velhop_gbfs/information/' },
  { title: 'Secteurs / Quartiers', text: 'Découpage administratif de Strasbourg.', link: 'https://data.strasbourg.eu/explore/dataset/strasbourg-en-28-quartiers/' },
  { title: 'Données démographiques', text: 'Population et déplacements.', link: 'https://mobiliscope.cnrs.fr/fr' },
  { title: 'Données OpenStreetMap', text: 'Données cartographiques libres.', link: 'https://www.openstreetmap.org' }
]

const basePath = `${import.meta.env.BASE_URL}dashboardR_Bateliers_EliaTerragni/`

const circleStyle = (idx) => ({
  width: `${state.districtsCenters[idx]?.radius ? state.districtsCenters[idx].radius * 2 : 10}px`,
  height: `${state.districtsCenters[idx]?.radius ? state.districtsCenters[idx].radius * 2 : 10}px`
})

const fetchJSON = async (file) => {
  const res = await fetch(`${basePath}${file}`)
  if (!res.ok) throw new Error(`Impossible de charger ${file}`)
  return res.json()
}

const fetchCSV = (file) => new Promise((resolve, reject) => {
  Papa.parse(`${basePath}${file}`, {
    download: true,
    header: true,
    skipEmptyLines: true,
    complete: (result) => resolve(result.data),
    error: (err) => reject(err)
  })
})

const normalizeNumber = (value) => {
  if (value === null || value === undefined || value === '') return null
  const cleaned = String(value).replace(/%/g, '').replace(',', '.').trim()
  const n = Number(cleaned)
  return Number.isFinite(n) ? n : null
}

const quantiles = (values, probs) => {
  const clean = values.filter((v) => Number.isFinite(v)).sort((a, b) => a - b)
  if (!clean.length) return probs.map(() => 0)
  return probs.map((p) => {
    const idx = (clean.length - 1) * p
    const lower = Math.floor(idx)
    const upper = Math.ceil(idx)
    if (lower === upper) return clean[lower]
    return clean[lower] + (clean[upper] - clean[lower]) * (idx - lower)
  })
}

const centerFromCoords = (geometry) => {
  const coords = geometry.type === 'MultiPolygon' ? geometry.coordinates.flat(2) : geometry.coordinates.flat()
  let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity
  coords.forEach(([x, y]) => {
    minX = Math.min(minX, x)
    maxX = Math.max(maxX, x)
    minY = Math.min(minY, y)
    maxY = Math.max(maxY, y)
  })
  return { lng: (minX + maxX) / 2, lat: (minY + maxY) / 2 }
}

const buildDistricts = (geojson, occ, pop) => {
  const partActifs = occ.reduce((acc, row) => {
    const d = Number(row.district)
    const val = normalizeNumber(row.actives)
    if (!Number.isFinite(d) || val === null) return acc
    if (!acc[d]) acc[d] = []
    acc[d].push(val)
    return acc
  }, {})

  const popMap = pop.reduce((acc, row) => {
    const d = Number(row.district)
    const val = normalizeNumber(row.pop0)
    if (!Number.isFinite(d) || val === null) return acc
    if (!acc[d]) acc[d] = []
    acc[d].push(val)
    return acc
  }, {})

  const getMean = (arr) => arr && arr.length ? arr.reduce((s, v) => s + v, 0) / arr.length : null

  const districts = geojson.features.map((f) => {
    const code = Number(f.properties.CODE_SEC)
    const part = partActifs[code] ? getMean(partActifs[code]) : null
    const popVal = popMap[code] ? getMean(popMap[code]) : null
    return {
      code,
      name: f.properties.LIB || `Secteur ${code}`,
      partActifs: part,
      pop: popVal,
      geometry: f.geometry
    }
  }).filter((d) => Number.isFinite(d.code))

  const breaks = quantiles(districts.map((d) => d.partActifs ?? 0), [0, 0.2, 0.4, 0.6, 0.8, 1]).map((v) => Math.round(v * 10) / 10)
  const labels = [
    `${breaks[0]}% - ${breaks[1]}%`,
    `${breaks[1]}% - ${breaks[2]}%`,
    `${breaks[2]}% - ${breaks[3]}%`,
    `${breaks[3]}% - ${breaks[4]}%`,
    `${breaks[4]}% - ${breaks[5]}%`
  ]

  const colors = ['#FFFFCC', '#FFEDA0', '#FED976', '#FEB24C', '#FD8D3C']
  legends.carte.colors = colors
  legends.carte.labels = labels
  legends.carte.breaks = breaks

  const popBreaks = quantiles(districts.map((d) => d.pop ?? 0), [0, 0.25, 0.5, 0.75, 1])
  const popLabels = [
    `≤ ${Math.round(popBreaks[1])}`,
    `${Math.round(popBreaks[1])} - ${Math.round(popBreaks[2])}`,
    `${Math.round(popBreaks[2])} - ${Math.round(popBreaks[3])}`,
    `> ${Math.round(popBreaks[3])}`
  ]
  legends.carte.popLabels = popLabels
  legends.carte.popBreaks = popBreaks

  const radiusDivisor = 18
  const centers = districts.map((d) => {
    const radius = d.pop ? Math.sqrt(d.pop) / radiusDivisor : 6
    return { ...centerFromCoords(d.geometry), radius }
  })
  legends.carte.popSizes = centers.map((c) => c.radius)

  return { districts, centers, breaks }
}

const normalizeEnquete = (rows) => rows.map((row) => {
  const genreRaw = (row.Genre || '').toLowerCase()
  const ageRaw = row.Age || row.Classe_age || ''
  const modeRaw = (row.Mode || row.Mode_transport || '').toLowerCase()

  const genre = ['femme', 'f'].includes(genreRaw) ? 'Femme'
    : ['homme', 'h'].includes(genreRaw) ? 'Homme'
      : 'Non spécifié'

  const age = ageRaw === 'moins de 20' || ageRaw === '<20' ? 'Moins de 20 ans'
    : ageRaw === '20-40' || ageRaw === '20-40 ans' ? '20-40 ans'
      : ageRaw === '40-60' || ageRaw === '40-60 ans' ? '40-60 ans'
        : ['60 et plus', '60+'].includes(ageRaw) ? '60 ans et plus'
          : ageRaw ? String(ageRaw) : 'Non spécifié'

  const classe = age.startsWith('Moins') ? '0-20 ans'
    : age === '20-40 ans' ? '20-40 ans'
      : age === '40-60 ans' ? '40-60 ans'
        : age === '60 ans et plus' ? '60+ ans'
          : 'Non spécifié'

  const mode = modeRaw.includes('pieton') || modeRaw.includes('piéton') ? 'Piéton'
    : modeRaw.includes('cycl') ? 'Cycliste'
      : modeRaw ? row.Mode : 'Non spécifié'

  return {
    ...row,
    Genre: genre,
    Age: age,
    Classe_age: classe,
    Mode_transport: mode,
    Heure: row.Heure
  }
})

const normalizeAmg = (features) => {
  const palette = ['#1D4ED8', '#0EA5E9', '#10B981', '#F59E0B', '#EF4444', '#6366F1', '#EC4899', '#14B8A6']
  const colorsByType = {}
  let colorIdx = 0

  const normalized = features.map((f) => {
    const ame = (f.properties.ame_g || f.properties.AME_G || 'Autres').trim()
    const rawDate = `${f.properties.d_service || ''}`.trim()
    const matchYear = rawDate.match(/\b(\d{4})\b/)
    const year = matchYear ? Number(matchYear[1]) : null
    if (!colorsByType[ame]) {
      colorsByType[ame] = palette[colorIdx % palette.length]
      colorIdx += 1
    }
    return {
      type: ame,
      year: year && year >= 2015 && year <= 2025 ? year : null,
      color: colorsByType[ame],
      geometry: f.geometry
    }
  })

  const capitalize = (str) => str.charAt(0).toUpperCase() + str.slice(1).toLowerCase()
  legends.mobilites.amenagements = Object.entries(colorsByType).map(([label, color]) => ({ label: capitalize(label), color }))
  return normalized
}

const loadData = async () => {
  try {
    const [stationsJSON, districtsGeo, amgGeo, fluxGeo, occCsv, popCsv, enqueteCsv] = await Promise.all([
      fetchJSON('stations.json'),
      fetchJSON('strasbourg_secteurs.geojson'),
      fetchJSON('amg_cycl_bnac.geojson'),
      fetchJSON('sirac_flux_trafic.geojson'),
      fetchCSV('strasbourg_occ_pct.csv'),
      fetchCSV('strasbourg_pop_nb.csv'),
      fetchCSV('tableau_complet_enquete_comove.csv')
    ])

    state.stations = (stationsJSON?.data?.stations || []).map((s) => ({
      id: s.station_id,
      name: s.name,
      lng: Number(s.lon),
      lat: Number(s.lat),
      capacity: s.capacity
    })).filter((s) => Number.isFinite(s.lng) && Number.isFinite(s.lat))

    const { districts, centers, breaks } = buildDistricts(districtsGeo, occCsv, popCsv)
    state.districts = districts
    state.districtsCenters = centers
    state.districtsGeoJSON = {
      type: 'FeatureCollection',
      features: districts.map((d) => ({
        type: 'Feature',
        properties: {
          code: d.code,
          name: d.name,
          part: d.partActifs,
          pop: d.pop,
          classe: d.partActifs !== null ? breaks.findIndex((b, idx) => d.partActifs <= breaks[idx + 1] || idx === breaks.length - 2) : 0
        },
        geometry: d.geometry
      }))
    }

    state.occupation = occCsv
    state.population = popCsv
    state.enquete = normalizeEnquete(enqueteCsv)

    const amg = normalizeAmg(amgGeo.features || [])
    state.amgCycl = amg
    const years = amg.map((a) => a.year).filter((y) => Number.isFinite(y))
    state.minYear = years.length ? Math.min(...years) : 2015
    state.maxYear = years.length ? Math.max(...years) : 2025
    filters.annee = state.maxYear

    state.fluxVoies = fluxGeo
  } catch (err) {
    state.error = err.message || 'Erreur de chargement des données'
  } finally {
    state.loading = false
  }
}

const initCarteMap = () => {
  if (!carteContainer.value || !state.districtsGeoJSON) return
  if (carteMap) carteMap.remove()

  const breaks = legends.carte.breaks && legends.carte.breaks.length ? legends.carte.breaks : [0, 20, 40, 60, 80, 100]
  const colors = legends.carte.colors.length ? legends.carte.colors : ['#ffffcc', '#ffeda0', '#fed976', '#feb24c', '#fd8d3c']

  carteMap = new maplibregl.Map({
    container: carteContainer.value,
    style: {
      version: 8,
      sources: {
        osm: {
          type: 'raster',
          tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
          tileSize: 256
        },
        districts: { type: 'geojson', data: state.districtsGeoJSON },
        centers: {
          type: 'geojson',
          data: {
            type: 'FeatureCollection',
            features: state.districtsCenters.map((c, idx) => ({
              type: 'Feature',
              properties: { radius: c.radius, pop: state.districts[idx]?.pop || 0, part: state.districts[idx]?.partActifs || 0 },
              geometry: { type: 'Point', coordinates: [c.lng, c.lat] }
            }))
          }
        }
      },
      layers: [
        { id: 'osm', type: 'raster', source: 'osm' },
        {
          id: 'district-fill',
          type: 'fill',
          source: 'districts',
          paint: {
            'fill-color': [
              'step', ['coalesce', ['get', 'part'], 0],
              colors[0],
              breaks[1], colors[1],
              breaks[2], colors[2],
              breaks[3], colors[3],
              breaks[4], colors[4]
            ],
            'fill-opacity': 0.65,
            'fill-outline-color': '#0f172a'
          }
        },
        { id: 'district-outline', type: 'line', source: 'districts', paint: { 'line-color': '#666', 'line-width': 0.6 } },
        {
          id: 'population-circles',
          type: 'circle',
          source: 'centers',
          paint: {
            'circle-radius': ['get', 'radius'],
            'circle-color': '#1d4ed8',
            'circle-stroke-color': '#0f172a',
            'circle-stroke-width': 1.2,
            'circle-opacity': 0.6
          }
        }
      ]
    },
    center: [7.75, 48.58],
    zoom: 12.2,
    attributionControl: false
  })

  carteMap.on('load', () => {
    if (!quaiMarkerCarte) {
      quaiMarkerCarte = new maplibregl.Marker({ color: '#e11d48' })
        .setLngLat([7.753601, 48.580602])
        .setPopup(new maplibregl.Popup({ offset: 12 }).setHTML('<b>Quai des Bateliers</b>'))
        .addTo(carteMap)
    }
  })
}

const initMobilitesMap = () => {
  if (!mobilitesContainer.value || !state.amgCycl.length) return
  if (mobilitesMap) mobilitesMap.remove()

  const amgGeo = {
    type: 'FeatureCollection',
    features: state.amgCycl.map((a) => ({
      type: 'Feature',
      properties: { type: a.type, year: a.year, color: a.color },
      geometry: a.geometry
    }))
  }

  // Build color match expression from amenagements
  const colorExpression = ['match', ['get', 'type']]
  const uniqueTypes = Array.from(new Set(state.amgCycl.map(a => a.type)))
  uniqueTypes.forEach(type => {
    const item = state.amgCycl.find(a => a.type === type)
    if (item && item.color) {
      colorExpression.push(type, item.color)
    }
  })
  colorExpression.push('#2563eb') // fallback

  mobilitesMap = new maplibregl.Map({
    container: mobilitesContainer.value,
    style: {
      version: 8,
      sources: {
        osm: { type: 'raster', tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'], tileSize: 256 },
        amg: { type: 'geojson', data: amgGeo },
        flux: { type: 'geojson', data: state.fluxVoies },
        stations: {
          type: 'geojson',
          data: {
            type: 'FeatureCollection',
            features: state.stations.map((s) => ({
              type: 'Feature',
              properties: { name: s.name, capacity: s.capacity },
              geometry: { type: 'Point', coordinates: [s.lng, s.lat] }
            }))
          }
        }
      },
      layers: [
        { id: 'osm', type: 'raster', source: 'osm' },
        {
          id: 'amg',
          type: 'line',
          source: 'amg',
          paint: {
            'line-color': colorExpression,
            'line-width': 3,
            'line-opacity': 0.9
          }
        },
        {
          id: 'flux',
          type: 'line',
          source: 'flux',
          paint: {
            'line-color': '#000',
            'line-width': [
              'match', ['get', 'etat'],
              1, 2,
              2, 4,
              3, 6,
              3
            ],
            'line-opacity': 0.35
          }
        },
        {
          id: 'stations-circle',
          type: 'circle',
          source: 'stations',
          paint: {
            'circle-radius': 8,
            'circle-color': '#fff',
            'circle-stroke-color': '#000',
            'circle-stroke-width': 3,
            'circle-opacity': 0.9
          }
        }
      ]
    },
    center: [7.75, 48.58],
    zoom: 13,
    attributionControl: false
  })

  mobilitesMap.on('load', () => {
    if (!quaiMarkerMob) {
      quaiMarkerMob = new maplibregl.Marker({ color: '#e11d48' })
        .setLngLat([7.753601, 48.580602])
        .setPopup(new maplibregl.Popup({ offset: 12 }).setHTML('<b>Quai des Bateliers</b>'))
        .addTo(mobilitesMap)
    }
    updateAmgFilter()
  })
}

const updateAmgFilter = () => {
  if (!mobilitesMap || !mobilitesMap.getLayer('amg')) return
  const year = filters.annee || state.maxYear
  mobilitesMap.setFilter('amg', [
    'any',
    ['!', ['has', 'year']],
    ['<=', ['get', 'year'], year]
  ])
}

const destroyCharts = () => {
  chartInstances.forEach((chart) => chart.destroy())
  chartInstances.clear()
}

const upsertChart = (key, ctx, config) => {
  if (chartInstances.has(key)) chartInstances.get(key).destroy()
  if (!ctx) return
  chartInstances.set(key, new Chart(ctx, config))
}

const buildCamembert = () => {
  const field = filters.camembert
  const labelsMap = new Map()
  state.enquete.forEach((row) => {
    const key = row[field]
    if (!key || key === 'Non spécifié') return
    labelsMap.set(key, (labelsMap.get(key) || 0) + 1)
  })
  const labels = Array.from(labelsMap.keys())
  const data = labels.map((l) => labelsMap.get(l))
  const colors = field === 'Genre' ? ['#3498DB', '#E74C3C', '#95A5A6']
    : field === 'Classe_age' ? ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7']
      : ['#9B59B6', '#1ABC9C', '#F39C12']

  upsertChart('pie', pieChart.value?.getContext('2d'), {
    type: 'pie',
    data: { labels, datasets: [{ data, backgroundColor: colors.slice(0, labels.length) }] },
    options: { plugins: { legend: { position: 'right' } } }
  })
}

const buildBarAge = () => {
  const grouped = {}
  state.enquete.forEach((r) => {
    if (!r.Mode_transport || r.Mode_transport === 'Non spécifié') return
    if (!r.Classe_age || r.Classe_age === 'Non spécifié') return
    const key = `${r.Mode_transport}|${r.Classe_age}`
    grouped[key] = (grouped[key] || 0) + 1
  })
  const modes = Array.from(new Set(state.enquete.map((r) => r.Mode_transport).filter((m) => m && m !== 'Non spécifié')))
  const ages = ['0-20 ans', '20-40 ans', '40-60 ans', '60+ ans']
  const datasets = ages.map((age, idx) => ({
    label: age,
    backgroundColor: ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4'][idx],
    data: modes.map((m) => grouped[`${m}|${age}`] || 0),
    stack: 'age'
  }))
  upsertChart('barAge', barAge.value?.getContext('2d'), {
    type: 'bar',
    data: { labels: modes, datasets },
    options: { responsive: true, scales: { x: { stacked: true }, y: { stacked: true } } }
  })
}

const buildBarGenre = () => {
  const grouped = {}
  state.enquete.forEach((r) => {
    if (!r.Mode_transport || r.Mode_transport === 'Non spécifié') return
    if (!r.Genre || r.Genre === 'Non spécifié') return
    const key = `${r.Mode_transport}|${r.Genre}`
    grouped[key] = (grouped[key] || 0) + 1
  })
  const modes = Array.from(new Set(state.enquete.map((r) => r.Mode_transport).filter((m) => m && m !== 'Non spécifié')))
  const genres = ['Femme', 'Homme']
  const datasets = genres.map((g, idx) => ({
    label: g,
    backgroundColor: ['#3498DB', '#E74C3C'][idx],
    data: modes.map((m) => grouped[`${m}|${g}`] || 0),
    stack: 'genre'
  }))
  upsertChart('barGenre', barGenre.value?.getContext('2d'), {
    type: 'bar',
    data: { labels: modes, datasets },
    options: { responsive: true, scales: { x: { stacked: true }, y: { stacked: true } } }
  })
}

const buildTemp = () => {
  const cat = filters.tempCategory
  const rows = state.enquete
    .map((r) => ({ ...r, heureNum: Number(String(r.Heure || '').split(':')[0]) }))
    .filter((r) => Number.isFinite(r.heureNum) && r.heureNum >= 8 && r.heureNum <= 19)

  const bucket = {}
  rows.forEach((r) => {
    let key = ''
    if (cat === 'motif') key = r.Motif_deplacement || r.Motif || ''
    if (cat === 'transport') key = r.Mode_transport
    if (cat === 'age') key = r.Classe_age
    if (cat === 'genre') key = r.Genre
    if (!key || key === 'Non spécifié') return
    const hour = r.heureNum
    if (!bucket[hour]) bucket[hour] = {}
    bucket[hour][key] = (bucket[hour][key] || 0) + 1
  })

  const labels = Object.keys(bucket).sort((a, b) => Number(a) - Number(b))
  const categories = Array.from(new Set(labels.flatMap((h) => Object.keys(bucket[h]))))
  const colorPalette = ['#3498DB', '#2ECC71', '#F39C12', '#9B59B6', '#E74C3C', '#16A085', '#8E44AD']
  const datasets = categories.map((c, idx) => ({
    label: c,
    backgroundColor: colorPalette[idx % colorPalette.length],
    data: labels.map((h) => bucket[h]?.[c] || 0),
    stack: 'stack'
  }))

  upsertChart('temp', tempChart.value?.getContext('2d'), {
    type: 'bar',
    data: { labels: labels.map((h) => `${h}h`), datasets },
    options: {
      responsive: true,
      scales: { x: { stacked: true }, y: { stacked: true, beginAtZero: true } }
    }
  })
}

const buildBubble = (key, targetRef, valueField, facetField, colors) => {
  const groups = {}
  state.enquete.forEach((r) => {
    const value = r[valueField]
    const facet = r[facetField]
    if (!value || value === 'Non spécifié') return
    if (!facet || facet === 'Non spécifié') return
    const k = `${facet}|${value}`
    groups[k] = (groups[k] || 0) + 1
  })

  const facets = Array.from(new Set(Object.keys(groups).map((k) => k.split('|')[0])))
  const values = Array.from(new Set(Object.keys(groups).map((k) => k.split('|')[1])))

  const datasets = facets.map((f, idx) => ({
    label: f,
    backgroundColor: colors[idx % colors.length],
    data: values.map((v, order) => ({ x: order + 1, y: groups[`${f}|${v}`] || 0, r: 6 + Math.sqrt(groups[`${f}|${v}`] || 1) * 2, label: v }))
  }))

  upsertChart(key, targetRef.value?.getContext('2d'), {
    type: 'bubble',
    data: { datasets },
    options: {
      parsing: false,
      scales: {
        x: { ticks: { callback: (val) => values[val - 1] || '' }, min: 0, max: values.length + 1 },
        y: { beginAtZero: true }
      },
      plugins: { legend: { position: 'bottom' } }
    }
  })
}

const buildCharts = () => {
  if (state.enquete.length === 0) return
  buildCamembert()
  buildBarAge()
  buildBarGenre()
  buildTemp()
  buildBubble('bubbleMode', bubbleMode, filters.ressentiMode, 'Mode_transport', ['#3498DB', '#E74C3C', '#2ECC71', '#9B59B6'])
  buildBubble('bubbleGenre', bubbleGenre, filters.ressentiGenre, 'Genre', ['#3498DB', '#E74C3C'])
  buildBubble('bubbleFrequence', bubbleFrequence, filters.ressentiFrequence, 'Frequence', ['#E67E22', '#1ABC9C', '#F1C40F', '#E74C3C'])
  buildBubble('bubbleAge', bubbleAge, filters.ressentiAge, 'Classe_age', ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4'])
}

watch(() => filters.annee, updateAmgFilter)
watch(() => [filters.camembert, filters.tempCategory, filters.ressentiMode, filters.ressentiGenre, filters.ressentiFrequence, filters.ressentiAge], () => buildCharts())

onMounted(async () => {
  await loadData()
  initCarteMap()
  initMobilitesMap()
  buildCharts()
  document.title = 'Dashboard R - Enquête COMOVE Strasbourg'
})

onBeforeUnmount(() => {
  if (carteMap) carteMap.remove()
  if (mobilitesMap) mobilitesMap.remove()
  destroyCharts()
  document.title = 'carto69'
})
</script>

<style scoped>
.dashboard-r {
  width: 100%;
  height: 100vh;
  position: relative;
  background: #f5f7fb;
  color: #1f2937;
  overflow: hidden;
}

.back-btn {
  position: absolute;
  top: 16px;
  right: 16px;
  z-index: 1500;
  padding: 10px 18px;
  background: #fff;
  border: 2px solid #0f172a;
  border-radius: 10px;
  cursor: pointer;
  font-weight: 600;
  color: #0f172a;
  box-shadow: 0 4px 12px rgba(15,23,42,0.15);
}

.layout {
  display: grid;
  grid-template-columns: 260px 1fr;
  height: 100%;
}

.sidebar-collapsed {
  grid-template-columns: 72px 1fr;
}

.sidebar {
  background: #0f172a;
  color: #fff;
  padding: 16px;
  overflow-y: auto;
}

.sidebar-header {
  position: relative;
  padding-right: 32px;
}

.sidebar h4 { margin: 0; }
.sidebar p { margin: 2px 0 12px; color: #cbd5e1; font-size: 0.9rem; }

.toggle {
  position: absolute;
  right: 0;
  top: 0;
  background: #1e293b;
  border: 1px solid #334155;
  color: #fff;
  border-radius: 6px;
  width: 28px;
  height: 28px;
  cursor: pointer;
}

nav { display: flex; flex-direction: column; gap: 8px; }

.nav-item {
  width: 100%;
  text-align: left;
  padding: 10px 12px;
  border: 1px solid #1e293b;
  border-radius: 8px;
  background: #111827;
  color: #e5e7eb;
  cursor: pointer;
}

.nav-item.active { background: #2563eb; border-color: #1d4ed8; }

.content {
  background: #f5f7fb;
  overflow-y: auto;
  position: relative;
  padding: 16px;
}

.content-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.content-header h3 { margin: 0; }
.content-header p { margin: 2px 0 0; color: #6b7280; }

.badge {
  background: #fbbf24;
  color: #92400e;
  padding: 4px 10px;
  border-radius: 999px;
  font-weight: 700;
}

.badge.success { background: #d1fae5; color: #065f46; }

.panel {
  position: relative;
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  padding: 8px;
  min-height: calc(100vh - 105px);
}

.map-wrapper {
  position: relative;
  width: 100%;
  height: calc(100vh - 140px);
  border-radius: 10px;
  overflow: hidden;
}

.map {
  width: 100%;
  height: 100%;
}

.floating-box {
  position: absolute;
  background: #fff;
  border: 1.5px solid #1f2937;
  border-radius: 10px;
  padding: 10px 12px;
  box-shadow: 0 8px 16px rgba(0,0,0,0.12);
  z-index: 1000;
}

.map-wrapper .title-box { top: 12px; right: 12px; max-width: 380px; }
.title-box h4 { margin: 0 0 4px; }
.title-box .sources { margin: 0; font-size: 0.85rem; color: #6b7280; }

.legend { bottom: 12px; right: 12px; width: 280px; }
.legend-title { font-weight: 700; margin-bottom: 6px; }
.legend-items { display: flex; flex-direction: column; gap: 6px; }
.legend-items.columns { flex-direction: row; flex-wrap: wrap; }
.legend-item { display: flex; align-items: center; gap: 6px; font-size: 0.9rem; }
.legend .color { width: 16px; height: 16px; border-radius: 4px; border: 1px solid #1f2937; }
.legend .station { width: 16px; height: 16px; border-radius: 50%; background: #fff; border: 3px solid #000; display: inline-block; }
.legend .line { width: 28px; background: #000; display: inline-block; }
.legend-circles { display: flex; flex-direction: column; gap: 4px; margin-top: 6px; }
.legend .circle { display: inline-block; border-radius: 50%; border: 1px solid #1f2937; background: rgba(37,99,235,0.15); }

.controls {
  position: absolute;
  top: 12px;
  left: 12px;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 10px;
  background: rgba(255,255,255,0.9);
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  box-shadow: 0 6px 12px rgba(0,0,0,0.08);
  z-index: 1100;
}

.controls input[type="range"] { flex: 1; }
.controls .value { min-width: 48px; text-align: right; font-weight: 700; }

.charts { display: flex; flex-direction: column; gap: 16px; }
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 12px; }
.chart-card {
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  padding: 12px;
  background: #fff;
}

.chart-header { display: flex; align-items: center; justify-content: space-between; gap: 10px; }
.chart-header h4 { margin: 0; }
.chart-header select { padding: 6px 8px; border-radius: 6px; border: 1px solid #d1d5db; }

.info { padding: 16px; }
.info-content { max-width: 860px; }
.source-box {
  border-left: 4px solid #2563eb;
  background: #f8fafc;
  padding: 10px 12px;
  margin-bottom: 10px;
  border-radius: 6px;
}
.link { background: #e0f2fe; border: 1px solid #bfdbfe; padding: 8px; border-radius: 6px; font-family: "Courier New", monospace; word-break: break-all; }
.refs { list-style: disc; padding-left: 20px; }

.error-box {
  background: #fee2e2;
  border: 1px solid #fecaca;
  color: #b91c1c;
  padding: 10px 12px;
  border-radius: 8px;
}

@media (max-width: 960px) {
  .layout { grid-template-columns: 1fr; }
  .sidebar { position: absolute; width: 260px; height: 100%; z-index: 1200; transform: translateX(-100%); transition: transform 0.3s ease; }
  .sidebar-collapsed .sidebar { transform: translateX(0); }
  .content { padding-top: 60px; }
  .back-btn { top: 12px; right: 12px; }
}
</style>
