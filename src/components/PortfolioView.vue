<template>
  <div class="portfolio-page">
    <aside class="sidebar">
      <button class="back" @click="$emit('back')">← Retour</button>
      <h1>Autres projets</h1>

      <hr />

      <div class="categories">
        <button 
          v-for="category in categories" 
          :key="category.id"
          class="category-btn"
          :class="{ active: activeCategory === category.id }"
          @click="activeCategory = category.id"
        >
          {{ category.icon }} {{ category.name }}
        </button>
      </div>
    </aside>

    <div class="portfolio-container">
      <div class="maps-grid">
        <div 
          v-for="map in filteredMaps" 
          :key="map.id"
          class="map-card"
          @click="openFullscreen(map)"
        >
          <div class="map-thumbnail">
            <img 
              v-if="map.image" 
              :src="map.image" 
              :alt="map.title"
            />
            <div v-else class="placeholder">
              <span>{{ map.icon }}</span>
            </div>
          </div>
          <div class="map-info">
            <h3>{{ map.title }}</h3>
            <p>{{ map.description }}</p>
            <span class="map-year">{{ map.year }}</span>
          </div>
        </div>
      </div>

      <!-- Placeholder si aucune carte -->
      <div v-if="filteredMaps.length === 0" class="empty-state">
        <span style="font-size: 4rem;">📦</span>
        <p>Aucune carte dans cette catégorie pour le moment</p>
        <small>Les projets seront ajoutés progressivement</small>
      </div>
    </div>

    <!-- Modal plein écran -->
    <div v-if="fullscreenMap" class="fullscreen-modal" @click="closeFullscreen">
      <div class="fullscreen-content">
        <button class="close-btn" @click="closeFullscreen">✕</button>
        <img v-if="fullscreenMap.image" :src="fullscreenMap.image" :alt="fullscreenMap.title" />
        <div class="fullscreen-info">
          <h2>{{ fullscreenMap.title }}</h2>
          <p>{{ fullscreenMap.description }}</p>
          <span>{{ fullscreenMap.year }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'PortfolioView',
  data() {
    return {
      activeCategory: 'cartes',
      fullscreenMap: null,
      categories: [
        { id: 'cartes', name: 'Cartes', icon: '🗺️' },
        { id: 'autre', name: 'Autre', icon: '📦' }
      ],
      maps: []
    }
  },
  created() {
    // Charge la liste des cartes depuis public/portfolio/cartes/index.json
    fetch('/portfolio/cartes/index.json')
      .then(r => r.json())
      .then(json => {
        if (json && Array.isArray(json.items)) {
          this.maps = json.items.map((item, idx) => ({
            id: idx + 1,
            title: item.title || 'Carte',
            description: item.description || '',
            year: item.year || '',
            category: 'cartes',
            icon: '🗺️',
            image: item.src
          }))
        }
      })
      .catch(() => {
        this.maps = []
      })
  },
  computed: {
    filteredMaps() {
      return this.maps.filter(map => {
        if (this.activeCategory === 'cartes') return map.category === 'cartes'
        if (this.activeCategory === 'autre') return map.category === 'autre'
        return true
      })
    }
  },
  methods: {
    openFullscreen(map) {
      if (!map.image) return
      if (map.image.endsWith('.pdf')) {
        window.open(map.image, '_blank')
      } else {
        this.fullscreenMap = map
      }
    },
    closeFullscreen() {
      this.fullscreenMap = null
    }
  }
}
</script>

<style scoped>
.portfolio-page {
  display: flex;
  width: 100%;
  height: 100vh;
  overflow: hidden;
  background: #1a1a1a;
  color: white;
}

.sidebar {
  width: 300px;
  height: 100vh;
  background: #242424;
  padding: 30px;
  overflow-y: auto;
  border-right: 1px solid #333;
}

.back {
  background: rgba(255, 255, 255, 0.1);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.2);
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  transition: all 0.3s ease;
  margin-bottom: 30px;
  width: 100%;
}

.back:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: translateX(-5px);
}

h1 {
  font-size: 1.8rem;
  margin: 0 0 15px 0;
  color: #fff;
}

.portfolio-info {
  margin-bottom: 20px;
  color: #aaa;
  font-size: 0.95rem;
}

hr {
  border: none;
  border-top: 1px solid #333;
  margin: 25px 0;
}

.categories {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.category-btn {
  background: rgba(255, 255, 255, 0.05);
  color: #ccc;
  border: 1px solid rgba(255, 255, 255, 0.1);
  padding: 12px 15px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.95rem;
  transition: all 0.3s ease;
  text-align: left;
}

.category-btn:hover {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.category-btn.active {
  background: #8B6F47;
  color: white;
  border-color: #8B6F47;
}

.portfolio-container {
  flex: 1;
  height: 100vh;
  overflow-y: auto;
  padding: 40px;
}

.maps-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 25px;
}

.map-card {
  background: #242424;
  border-radius: 10px;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.3s ease;
  border: 1px solid #333;
}

.map-card:hover {
  transform: translateY(-8px);
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
  border-color: #8B6F47;
}

.map-thumbnail {
  width: 100%;
  height: 200px;
  background: #1a1a1a;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.map-thumbnail img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 3rem;
  background: linear-gradient(135deg, #1a1a1a 0%, #2a2a2a 100%);
}

.map-info {
  padding: 20px;
}

.map-info h3 {
  margin: 0 0 8px 0;
  font-size: 1.2rem;
  color: white;
}

.map-info p {
  margin: 0 0 12px 0;
  color: #aaa;
  font-size: 0.9rem;
  line-height: 1.4;
}

.map-year {
  display: inline-block;
  background: rgba(139, 111, 71, 0.2);
  color: #8B6F47;
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 0.85rem;
  font-weight: 500;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 60vh;
  color: #666;
  text-align: center;
}

.empty-state p {
  font-size: 1.2rem;
  margin: 20px 0 10px 0;
}

.empty-state small {
  color: #555;
}

.fullscreen-modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.95);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.fullscreen-content {
  position: relative;
  max-width: 90vw;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.fullscreen-content img {
  max-width: 100%;
  max-height: 80vh;
  object-fit: contain;
  border-radius: 8px;
  box-shadow: 0 10px 50px rgba(0, 0, 0, 0.5);
}

.fullscreen-info {
  margin-top: 20px;
  text-align: center;
  color: white;
}

.fullscreen-info h2 {
  margin: 0 0 10px 0;
  font-size: 1.5rem;
}

.fullscreen-info p {
  margin: 0 0 10px 0;
  color: #ccc;
}

.close-btn {
  position: absolute;
  top: -50px;
  right: 0;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.3);
  color: white;
  font-size: 2rem;
  width: 50px;
  height: 50px;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: rotate(90deg);
}

@media (max-width: 768px) {
  .portfolio-page {
    flex-direction: column;
  }

  .sidebar {
    width: 100%;
    height: auto;
    border-right: none;
    border-bottom: 1px solid #333;
  }

  .maps-grid {
    grid-template-columns: 1fr;
  }
}
</style>
