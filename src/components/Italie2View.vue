<template>
  <div class="italie2-container">
    <button class="back-button" @click="$emit('back')" title="Retour à l'accueil">← Accueil</button>
    
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

    <div class="content">
      <!-- Barre de recherche et filtres -->
      <div class="search-section">
        <input 
          v-model="searchQuery" 
          type="text" 
          placeholder="🔍 Rechercher un magasin..."
          class="search-input"
        >
        <div class="filters">
          <button 
            v-for="cat in uniqueCategories" 
            :key="cat"
            @click="selectedCategory = selectedCategory === cat ? null : cat"
            :class="['filter-btn', { active: selectedCategory === cat }]"
          >
            {{ cat }}
          </button>
        </div>
      </div>

      <!-- Grille des magasins de l'étage actuel -->
      <div class="stores-grid">
        <div 
          v-for="store in filteredStores" 
          :key="store.id"
          class="store-card"
          @click="selectStore(store)"
          :class="{ selected: selectedStore?.id === store.id }"
        >
          <div v-if="store.logo" class="store-logo">
            <img :src="'https:' + store.logo" :alt="store.name" @error="handleImageError">
          </div>
          <div v-else class="store-placeholder">
            {{ store.name.charAt(0).toUpperCase() }}
          </div>
          <div class="store-info">
            <h3>{{ store.name }}</h3>
            <p class="category">{{ store.category }}</p>
          </div>
        </div>
      </div>

      <!-- Détail du magasin sélectionné -->
      <div v-if="selectedStore" class="store-detail">
        <div class="detail-header">
          <h2>{{ selectedStore.name }}</h2>
          <button @click="selectedStore = null" class="close-btn">✕</button>
        </div>
        <div class="detail-content">
          <div class="detail-left">
            <div v-if="selectedStore.logo" class="detail-logo">
              <img :src="selectedStore.logo" :alt="selectedStore.name">
            </div>
          </div>
          <div class="detail-right">
            <div class="info-row">
              <span class="label">Catégorie:</span>
              <span class="value">{{ selectedStore.category }}</span>
            </div>
            <div class="info-row">
              <span class="label">Plan d'étage:</span>
              <span class="value">{{ selectedStore.floorPlanID || 'N/A' }}</span>
            </div>
            <div v-if="selectedStore.description" class="info-row">
              <span class="label">Description:</span>
              <span class="value">{{ selectedStore.description }}</span>
            </div>
            <div class="info-row">
              <span class="label">Code:</span>
              <span class="value code">{{ selectedStore.slug }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Statistiques -->
      <div class="stats">
        <div class="stat">
          <span class="stat-number">{{ filteredStores.length }}</span>
          <span class="stat-label">Magasins affichés</span>
        </div>
        <div class="stat">
          <span class="stat-number">{{ uniqueCategories.length }}</span>
          <span class="stat-label">Catégories</span>
        </div>
        <div class="stat">
          <span class="stat-number">{{ storesWithFloorPlan }}</span>
          <span class="stat-label">Plans disponibles</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Italie2View',
  data() {
    return {
      floors: {},
      currentFloor: 'floor2', // Démarrer au 2ème étage
      searchQuery: '',
      selectedCategory: null,
      selectedStore: null,
      meetingPlaceInfo: null
    }
  },
  computed: {
    currentFloorStores() {
      return this.floors[this.currentFloor]?.stores || []
    },
    uniqueCategories() {
      const categories = [...new Set(this.currentFloorStores.map(s => s.category))].sort()
      return categories
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

      if (this.selectedCategory) {
        filtered = filtered.filter(s => s.category === this.selectedCategory)
      }

      return filtered.sort((a, b) => a.name.localeCompare(b.name))
    },
    storesWithFloorPlan() {
      return this.currentFloorStores.filter(s => s.floorPlanID).length
    }
  },
  async mounted() {
    await this.loadFloors()
  },
  methods: {
    async loadFloors() {
      try {
        const response = await fetch('/sens-italie-deux/floors-data.json')
        const data = await response.json()
        this.meetingPlaceInfo = data.meetingPlace
        this.floors = data.floors
      } catch (error) {
        console.error('Erreur lors du chargement des étages:', error)
        this.floors = {}
      }
    },
    selectStore(store) {
      this.selectedStore = store
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
    }
  },
  watch: {
    currentFloor() {
      // Réinitialiser les filtres quand on change d'étage
      this.searchQuery = ''
      this.selectedCategory = null
      this.selectedStore = null
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

.back-button {
  position: absolute;
  top: 20px;
  right: 20px;
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

.back-button:hover {
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
  max-width: 1400px;
  margin: 0 auto;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 16px;
  padding: 30px;
  box-shadow: 0 10px 40px rgba(0,0,0,0.5);
}

.search-section {
  margin-bottom: 30px;
}

.search-input {
  width: 100%;
  padding: 12px 16px;
  font-size: 16px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  margin-bottom: 15px;
  transition: all 0.3s ease;
}

.search-input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.filters {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  max-height: 120px;
  overflow-y: auto;
  padding-right: 10px;
}

.filter-btn {
  padding: 6px 14px;
  background: #f0f0f0;
  border: 2px solid transparent;
  border-radius: 20px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.filter-btn:hover {
  background: #e8e8e8;
}

.filter-btn.active {
  background: #667eea;
  color: white;
  border-color: #667eea;
}

.stores-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 15px;
  margin-bottom: 30px;
  max-height: 400px;
  overflow-y: auto;
  padding: 10px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background: #fafafa;
}

.store-card {
  background: white;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  padding: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: center;
}

.store-card:hover {
  border-color: #667eea;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
  transform: translateY(-2px);
}

.store-card.selected {
  border-color: #667eea;
  background: #f0f4ff;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.store-logo {
  height: 60px;
  margin-bottom: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.store-logo img {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
}

.store-placeholder {
  height: 60px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  font-weight: bold;
  border-radius: 6px;
  margin-bottom: 8px;
}

.store-info h3 {
  margin: 0;
  font-size: 12px;
  font-weight: 600;
  color: #333;
}

.category {
  font-size: 11px;
  color: #999;
  margin: 3px 0;
}

.floor-plan {
  font-size: 10px;
  color: #667eea;
  margin: 3px 0;
}

.store-detail {
  background: #f9f9f9;
  border: 2px solid #667eea;
  border-radius: 8px;
  padding: 20px;
  margin-top: 20px;
}

.detail-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.detail-header h2 {
  margin: 0;
  color: #333;
}

.close-btn {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #999;
  transition: color 0.2s ease;
}

.close-btn:hover {
  color: #333;
}

.detail-content {
  display: grid;
  grid-template-columns: 150px 1fr;
  gap: 20px;
}

.detail-logo {
  text-align: center;
}

.detail-logo img {
  max-width: 100%;
  max-height: 200px;
  object-fit: contain;
}

.detail-right {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.info-row {
  display: flex;
  gap: 15px;
}

.label {
  font-weight: 600;
  color: #667eea;
  min-width: 100px;
}

.value {
  color: #333;
  flex: 1;
}

.value.code {
  font-family: 'Courier New', monospace;
  font-size: 12px;
  background: #f0f0f0;
  padding: 2px 6px;
  border-radius: 3px;
}

.stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  margin-top: 30px;
  padding-top: 30px;
  border-top: 2px solid #e0e0e0;
}

.stat {
  text-align: center;
}

.stat-number {
  display: block;
  font-size: 2em;
  font-weight: bold;
  color: #667eea;
}

.stat-label {
  display: block;
  font-size: 13px;
  color: #999;
  margin-top: 5px;
}

/* Scrollbar personnalisée */
.stores-grid::-webkit-scrollbar {
  width: 8px;
}

.stores-grid::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 10px;
}

.stores-grid::-webkit-scrollbar-thumb {
  background: #667eea;
  border-radius: 10px;
}

.stores-grid::-webkit-scrollbar-thumb:hover {
  background: #764ba2;
}
</style>
