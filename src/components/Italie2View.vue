<template>
  <div class="italie2-container">
    <button class="back-button-left" @click="$emit('back')" title="Retour à l'accueil">← Accueil</button>
    
    <div class="header">
      <h1>Italie Deux</h1>
      <p class="subtitle">Plan interactif du centre</p>
    </div>

    <!-- Onglets des étages -->
    <div class="floors-tabs">
      <button 
        v-for="(floorData, key) in floors" 
        :key="key"
        @click="currentFloor = key"
        :class="['floor-tab', { active: currentFloor === key }]"
      >
        <span class="floor-icon">{{ getFloorIcon(key) }}</span>
        <span class="floor-name">{{ floorData.name }}</span>
        <span class="floor-count">{{ floorData.stores.length }}</span>
      </button>
    </div>

    <!-- Plans vectoriels de chaque étage -->
    <Italie2SvgPlans style="margin-bottom:32px;" />

    <div class="content">
      <!-- Vue en deux colonnes : Carte + Liste -->
      <div class="main-layout">
        <!-- Carte de l'étage (SVG) -->
        <div class="floor-map-container" :style="floorBgStyle">
          <div v-if="isLoading" class="map-empty">Chargement…</div>
          <svg v-else class="floor-svg" :width="svgWidth" :height="svgHeight" viewBox="0 0 800 600">
            <!-- Titre d'étage -->
            <text x="400" y="28" text-anchor="middle" font-size="20" font-weight="800" fill="#0f172a">
              {{ floorTitle }}
            </text>
            <rect x="40" y="40" width="720" height="520" rx="16" ry="16" fill="#f8fafc" stroke="#d0d5db" stroke-width="2" />
            <g stroke="#eef2f7" stroke-width="1">
              <line v-for="i in 12" :key="'v'+i" :x1="60 + (i-1)*60" y1="60" :x2="60 + (i-1)*60" y2="540" />
              <line v-for="j in 8" :key="'h'+j" x1="60" :y1="60 + (j-1)*60" x2="740" :y2="60 + (j-1)*60" />
            </g>
            <!-- Schéma parking basique -->
            <g v-if="currentFloor === 'parking'">
              <rect x="60" y="80" width="680" height="440" fill="#e2e8f0" stroke="#cbd5e1"/>
              <g v-for="r in 4" :key="'row'+r">
                <rect :x="80" :y="90 + (r-1)*100" width="280" height="70" rx="8" fill="#ffffff" stroke="#94a3b8"/>
                <rect :x="440" :y="90 + (r-1)*100" width="280" height="70" rx="8" fill="#ffffff" stroke="#94a3b8"/>
              </g>
              <text x="400" y="560" text-anchor="middle" font-size="12" fill="#475569">Allées parking indicatives</text>
            </g>
            <g v-if="hasStores" v-for="(store, idx) in currentFloorStores" :key="store.id">
              <circle :cx="storeX(idx)" :cy="storeY(idx)" r="7" :fill="getCategoryColor(store.category)" />
              <text :x="storeX(idx) + 12" :y="storeY(idx) + 4" font-size="12" font-weight="600" fill="#1f2937">{{ store.name }}</text>
            </g>
            <g v-else>
              <text x="400" y="310" text-anchor="middle" font-size="18" font-weight="700" fill="#334155">
                {{ currentFloor === 'parking' ? 'Plan Parking' : 'Aucune donnée' }}
              </text>
            </g>
          </svg>
          <div class="map-legend">
            <div class="legend-item" v-for="(count, category) in categoryCounts" :key="category" v-if="hasStores">
              <span class="legend-color" :style="{ background: getCategoryColor(category) }"></span>
              <span class="legend-label">{{ category }} ({{ count }})</span>
            </div>
            <div v-else class="legend-item">
              <span class="legend-color" style="background:#94a3b8"></span>
              <span class="legend-label">{{ currentFloor === 'parking' ? 'Parking' : 'Vide' }}</span>
            </div>
          </div>
        </div>

        <!-- Liste des magasins à droite -->
        <div class="stores-sidebar">
          <!-- Barre de recherche -->
          <div class="search-section">
            <input 
              v-model="searchQuery" 
              type="text" 
              placeholder="🔍 Rechercher..."
              class="search-input"
            >
          </div>

          <!-- Liste scrollable -->
          <div class="stores-list">
            <div 
              v-for="store in filteredStores" 
              :key="store.id"
              class="store-item"
              @click="selectStore(store)"
              @mouseenter="highlightStore(store)"
              @mouseleave="unhighlightStore()"
              :class="{ selected: selectedStore?.id === store.id }"
            >
              <div class="store-item-header">
                <div v-if="store.logo" class="store-item-logo">
                  <img :src="'https:' + store.logo" :alt="store.name" @error="handleImageError">
                </div>
                <div v-else class="store-item-placeholder">
                  {{ store.name.charAt(0).toUpperCase() }}
                </div>
                <div class="store-item-info">
                  <h4>{{ store.name }}</h4>
                  <p class="category-tag" :style="{ background: getCategoryColor(store.category) }">
                    {{ store.category }}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import Italie2SvgPlans from './Italie2SvgPlans.vue'

export default {
  name: 'Italie2View',
  components: { Italie2SvgPlans },
  data() {
    return {
      floors: {},
      currentFloor: 'floor2',
      searchQuery: '',
      selectedStore: null,
      meetingPlaceInfo: null,
      svgWidth: 800,
      svgHeight: 600,
      highlightedMarker: null,
      isLoading: true
    }
  },
  computed: {
    currentFloorStores() {
      return this.floors[this.currentFloor]?.stores || []
    },
    hasStores() {
      return (this.currentFloorStores?.length || 0) > 0
    },
    floorTitle() {
      return this.floors[this.currentFloor]?.name || 'Étage'
    },
    floorBgStyle() {
      const base = `/sens-italie-deux/floors/${this.currentFloor}`
      const url = `${base}.svg`
      const urlPng = `${base}.png`
      const urlJpg = `${base}.jpg`
      return {
        backgroundImage: `url('${url}'), url('${urlPng}'), url('${urlJpg}')`,
        backgroundSize: 'contain',
        backgroundRepeat: 'no-repeat',
        backgroundPosition: 'center'
      }
    },
    filteredStores() {
      let filtered = this.currentFloorStores
      if (this.searchQuery) {
        const query = this.searchQuery.toLowerCase()
        filtered = filtered.filter(s => 
          s.name.toLowerCase().includes(query) || 
          s.category.toLowerCase().includes(query)
        )
      }
      return filtered.sort((a, b) => a.name.localeCompare(b.name))
    },
    categoryCounts() {
      const counts = {}
      this.currentFloorStores.forEach(store => {
        counts[store.category] = (counts[store.category] || 0) + 1
      })
      return counts
    }
  },
  async mounted() {
    await this.loadFloors()
  },
  beforeUnmount() {},
  methods: {
    async loadFloors() {
      try {
        const response = await fetch('/sens-italie-deux/floors-data.json')
        const data = await response.json()
        this.meetingPlaceInfo = data.meetingPlace
        this.floors = data.floors
      } catch (error) {
        console.error('Erreur chargement étages:', error)
        this.floors = {}
      } finally {
        this.isLoading = false
      }
    },
    
    // Positionnement des magasins sur une grille régulière (SVG)
    storeX(idx) {
      const cols = 10
      const col = idx % cols
      return 80 + col * 65
    },
    storeY(idx) {
      const cols = 10
      const row = Math.floor(idx / cols)
      return 90 + row * 65
    },

    async loadFloorPlan() {
      // plus de rendu 3D; les données sont utilisées par le SVG
      return
    },

    createBasicFloorPlan() {},

    addStoreMarkers() {},

    animate() {},

    selectStore(store) {
      this.selectedStore = store
    },

    highlightStore(store) {
      this.highlightedMarker = store
    },

    unhighlightStore() {
      this.highlightedMarker = null
    },

    handleImageError(event) {
      event.target.style.display = 'none'
    },

    getFloorIcon(floorKey) {
      const icons = {
        'parking': '🅿️',
        'floor1': '1️⃣',
        'floor2': '2️⃣',
        'floor3': '3️⃣'
      }
      return icons[floorKey] || '📍'
    },

    getCategoryColor(category) {
      const colors = {
        'Alimentation': '#FF6B6B',
        'Mode Femme': '#FF69B4',
        'Mode Homme': '#4169E1',
        'Chaussures': '#8B4513',
        'Beauté': '#FFB6C1',
        'Bijoux': '#FFD700',
        'Accessoires et montres': '#DDA0DD',
        'Services': '#20B2AA',
        'Maison et Décoration': '#FFA500',
        'default': '#95A5A6'
      }
      return colors[category] || colors.default
    },

    getCategoryColorHex(category) {
      const color = this.getCategoryColor(category)
      return parseInt(color.replace('#', '0x'), 16)
    }
  },
  
  watch: {
    currentFloor() {
      this.searchQuery = ''
      this.selectedStore = null
      // le SVG se met à jour automatiquement via computed
    }
  }
}
</script>

<style scoped>
.italie2-container {
  width: 100%;
  min-height: 100vh;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
  padding: 20px;
  position: relative;
}

.back-button-left {
  position: absolute;
  top: 20px;
  left: 20px;
  background: rgba(255, 255, 255, 0.95);
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
  z-index: 100;
  transition: all 0.3s ease;
}

.back-button-left:hover {
  background: #fff;
  box-shadow: 0 4px 12px rgba(0,0,0,0.2);
  transform: translateY(-2px);
}

.header {
  text-align: center;
  margin-bottom: 30px;
  color: white;
}

.header h1 {
  font-size: 2.5em;
  margin: 0;
  text-shadow: 0 2px 4px rgba(0,0,0,0.3);
  font-weight: 700;
}

.subtitle {
  font-size: 1.1em;
  margin: 10px 0 0 0;
  opacity: 0.85;
}

/* Onglets des étages */
.floors-tabs {
  display: flex;
  gap: 10px;
  justify-content: center;
  margin-bottom: 30px;
  flex-wrap: wrap;
}

.floor-tab {
  background: rgba(255, 255, 255, 0.1);
  border: 2px solid rgba(255, 255, 255, 0.2);
  color: white;
  padding: 12px 20px;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 14px;
  font-weight: 600;
  backdrop-filter: blur(10px);
}

.floor-tab:hover {
  background: rgba(255, 255, 255, 0.15);
  border-color: rgba(255, 255, 255, 0.4);
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(0,0,0,0.3);
}

.floor-tab.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-color: #667eea;
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
}

.floor-icon {
  font-size: 20px;
}

.floor-name {
  font-weight: 600;
}

.floor-count {
  background: rgba(255, 255, 255, 0.2);
  padding: 2px 8px;
  border-radius: 10px;
  font-size: 12px;
  font-weight: 700;
}

.floor-tab.active .floor-count {
  background: rgba(255, 255, 255, 0.3);
}

.content {
  max-width: 1600px;
  margin: 0 auto;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 16px;
  padding: 20px;
  box-shadow: 0 10px 40px rgba(0,0,0,0.5);
}

/* Layout principal : Carte + Sidebar */
.main-layout {
  display: grid;
  grid-template-columns: 1fr 350px;
  gap: 20px;
  height: 600px;
}

/* Carte de l'étage */
.floor-map-container {
  position: relative;
  background: #f1f5f9;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: inset 0 2px 8px rgba(0,0,0,0.1);
  height: 600px; /* garantir la hauteur de rendu du SVG */
}

.floor-svg {
  width: 100%;
  height: 100%;
  display: block;
}

.map-empty {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #334155;
  font-weight: 600;
  background: rgba(255,255,255,0.8);
}

.map-legend {
  position: absolute;
  bottom: 15px;
  left: 15px;
  background: rgba(255, 255, 255, 0.95);
  padding: 12px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
  max-height: 200px;
  overflow-y: auto;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
  font-size: 12px;
}

.legend-color {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  flex-shrink: 0;
}

.legend-label {
  color: #333;
  font-weight: 500;
}

/* Sidebar des magasins */
.stores-sidebar {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.search-section {
  flex-shrink: 0;
}

.search-input {
  width: 100%;
  padding: 12px 16px;
  font-size: 14px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.search-input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

/* Liste scrollable des magasins */
.stores-list {
  flex: 1;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding-right: 5px;
}

.store-item {
  background: white;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  padding: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.store-item:hover {
  border-color: #667eea;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
  transform: translateX(3px);
}

.store-item.selected {
  border-color: #667eea;
  background: #f0f4ff;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.store-item-header {
  display: flex;
  align-items: center;
  gap: 12px;
}

.store-item-logo {
  width: 50px;
  height: 50px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #fafafa;
  border-radius: 6px;
}

.store-item-logo img {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
}

.store-item-placeholder {
  width: 50px;
  height: 50px;
  flex-shrink: 0;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  font-weight: bold;
  border-radius: 6px;
}

.store-item-info {
  flex: 1;
  min-width: 0;
}

.store-item-info h4 {
  margin: 0 0 5px 0;
  font-size: 14px;
  font-weight: 600;
  color: #333;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.category-tag {
  display: inline-block;
  padding: 3px 8px;
  border-radius: 12px;
  font-size: 11px;
  color: white;
  font-weight: 600;
}

/* Scrollbar personnalisée */
.stores-list::-webkit-scrollbar {
  width: 6px;
}

.stores-list::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 10px;
}

.stores-list::-webkit-scrollbar-thumb {
  background: #667eea;
  border-radius: 10px;
}

.stores-list::-webkit-scrollbar-thumb:hover {
  background: #764ba2;
}
</style>
