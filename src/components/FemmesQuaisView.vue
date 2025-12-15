<template>
  <div class="femmes-quais-page">
    <aside class="text-panel">
      <button class="back" @click="$emit('back')">← Retour</button>
      <h1>Les femmes sur les quais du Rhône</h1>
      
      <div class="text-content">
        <textarea 
          v-model="userText" 
          @input="saveText"
          placeholder="Écrivez vos observations, analyses ou commentaires ici..."
          class="text-editor"
        ></textarea>
        
        <div class="text-info">
          <small>{{ wordCount }} mots · Sauvegarde automatique</small>
        </div>
      </div>

      <hr />

      <div class="navigation-tabs">
        <button 
          class="tab-btn"
          :class="{ active: activeTab === 'cartes' }"
          @click="activeTab = 'cartes'"
        >
          📍 Cartes sensibles
        </button>
        <button 
          class="tab-btn"
          :class="{ active: activeTab === 'sources' }"
          @click="activeTab = 'sources'"
        >
          📚 Sources & Méthodologie
        </button>
      </div>
    </aside>

    <div class="maps-container">
      <!-- Cartes sensibles -->
      <div v-if="activeTab === 'cartes'" class="maps-grid">
        <div class="map-item">
          <img 
            src="/femmes-quais/carte-1.png" 
            alt="Carte sensible 1"
            @click="openFullscreen('/femmes-quais/carte-1.png')"
          />
        </div>
        <div class="map-item">
          <img 
            src="/femmes-quais/carte-2.png" 
            alt="Carte sensible 2"
            @click="openFullscreen('/femmes-quais/carte-2.png')"
          />
        </div>
      </div>

      <!-- Sources et méthodologie -->
      <div v-else class="sources-grid">
        <div class="source-item">
          <img 
            src="/femmes-quais/source-3.png" 
            alt="Sources et méthodologie - page 1"
            @click="openFullscreen('/femmes-quais/source-3.png')"
          />
        </div>
        <div class="source-item">
          <img 
            src="/femmes-quais/source-4.png" 
            alt="Sources et méthodologie - page 2"
            @click="openFullscreen('/femmes-quais/source-4.png')"
          />
        </div>
      </div>
    </div>

    <!-- Modal plein écran -->
    <div v-if="fullscreenImage" class="fullscreen-modal" @click="closeFullscreen">
      <div class="fullscreen-content">
        <button class="close-btn" @click="closeFullscreen">✕</button>
        <img :src="fullscreenImage" alt="Vue plein écran" />
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'FemmesQuaisView',
  data() {
    return {
      activeTab: 'cartes',
      userText: '',
      fullscreenImage: null
    }
  },
  computed: {
    wordCount() {
      return this.userText.trim().split(/\s+/).filter(w => w.length > 0).length
    }
  },
  mounted() {
    this.loadText()
  },
  methods: {
    saveText() {
      try {
        localStorage.setItem('femmesQuaisText', this.userText)
      } catch (e) {
        console.error('Erreur sauvegarde:', e)
      }
    },
    loadText() {
      try {
        const saved = localStorage.getItem('femmesQuaisText')
        if (saved) {
          this.userText = saved
        }
      } catch (e) {
        console.error('Erreur chargement:', e)
      }
    },
    openFullscreen(imageSrc) {
      this.fullscreenImage = imageSrc
    },
    closeFullscreen() {
      this.fullscreenImage = null
    }
  }
}
</script>

<style scoped>
.femmes-quais-page {
  display: flex;
  width: 100%;
  height: 100vh;
  background: #f5f5f5;
}

.text-panel {
  width: 400px;
  height: 100%;
  background: #fff;
  border-right: 2px solid #ddd;
  overflow-y: auto;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 15px;
  box-shadow: 2px 0 10px rgba(0,0,0,0.1);
}

.back {
  background: #2171b5;
  color: white;
  border: none;
  padding: 10px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  margin-bottom: 10px;
  transition: background 0.2s;
}

.back:hover {
  background: #1a5a8e;
}

h1 {
  font-size: 1.6rem;
  font-weight: 700;
  margin: 0;
  color: #333;
  line-height: 1.3;
}

hr {
  border: none;
  border-top: 1px solid #e0e0e0;
  margin: 10px 0;
}

.text-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-height: 300px;
}

.text-editor {
  flex: 1;
  padding: 12px;
  border: 2px solid #ddd;
  border-radius: 6px;
  font-size: 0.95rem;
  font-family: inherit;
  line-height: 1.6;
  resize: none;
  background: #fafafa;
  color: #333;
}

.text-editor:focus {
  outline: none;
  border-color: #2171b5;
  background: #fff;
}

.text-info {
  text-align: right;
  color: #666;
  font-size: 0.85rem;
}

.navigation-tabs {
  display: flex;
  gap: 8px;
}

.tab-btn {
  flex: 1;
  padding: 12px;
  background: #f5f5f5;
  border: 2px solid #ddd;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
  font-weight: 500;
  color: #666;
  transition: all 0.2s;
}

.tab-btn:hover {
  background: #e8e8e8;
  border-color: #bbb;
}

.tab-btn.active {
  background: #2171b5;
  border-color: #2171b5;
  color: white;
}

.maps-container {
  flex: 1;
  padding: 30px;
  overflow-y: auto;
  background: #f5f5f5;
}

.maps-grid,
.sources-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
  max-width: 1800px;
  margin: 0 auto;
}

.map-item,
.source-item {
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
}

.map-item:hover,
.source-item:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 16px rgba(0,0,0,0.15);
}

.map-item img,
.source-item img {
  width: 100%;
  height: auto;
  display: block;
}

.fullscreen-modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.95);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
  cursor: zoom-out;
}

.fullscreen-content {
  position: relative;
  max-width: 95%;
  max-height: 95%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.fullscreen-content img {
  max-width: 100%;
  max-height: 95vh;
  object-fit: contain;
  cursor: default;
}

.close-btn {
  position: absolute;
  top: -50px;
  right: 0;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: none;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  font-size: 1.5rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

/* Responsive */
@media (max-width: 1200px) {
  .maps-grid,
  .sources-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .femmes-quais-page {
    flex-direction: column;
  }

  .text-panel {
    width: 100%;
    height: auto;
    max-height: 40vh;
  }

  .maps-container {
    padding: 15px;
  }
}

/* Scrollbar personnalisée */
.text-panel::-webkit-scrollbar,
.maps-container::-webkit-scrollbar {
  width: 8px;
}

.text-panel::-webkit-scrollbar-track,
.maps-container::-webkit-scrollbar-track {
  background: #f5f5f5;
}

.text-panel::-webkit-scrollbar-thumb,
.maps-container::-webkit-scrollbar-thumb {
  background: #ccc;
  border-radius: 4px;
}

.text-panel::-webkit-scrollbar-thumb:hover,
.maps-container::-webkit-scrollbar-thumb:hover {
  background: #aaa;
}
</style>
