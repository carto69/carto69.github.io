<template>
  <div class="femmes-quais-page">
    <aside class="sidebar">
      <button class="back" @click="$emit('back')">← Retour</button>
      <h1>Genre et espace public</h1>
      
      <div class="project-info">
        <p>Cartes sensibles produites dans le cadre d'une enquête de L2 sur le thème "Genre et Espace Public" où nous avons enquêté sur le ressenti des femmes sur les quais du Rhône à Lyon.</p>
      </div>

      <hr />

      <div class="tabs">
        <button 
          v-for="tab in tabs" 
          :key="tab.id"
          class="tab-btn"
          :class="{ active: activeTab === tab.id }"
          @click="activeTab = tab.id"
        >
          {{ tab.icon }} {{ tab.name }}
        </button>
      </div>
    </aside>

    <div class="content-container">
      <div v-if="activeContent" class="image-viewer">
        <img 
          :src="activeContent" 
          :alt="activeTabName"
          @click="toggleFullscreen"
          class="main-image"
        />
        <p class="image-caption">{{ activeTabName }}</p>
      </div>

      <div v-else class="empty-state">
        <span style="font-size: 4rem;">🗺️</span>
        <p>Sélectionnez un onglet pour voir le contenu</p>
      </div>
    </div>

    <!-- Modal plein écran -->
    <div v-if="fullscreen" class="fullscreen-modal" @click="toggleFullscreen">
      <button class="close-btn" @click.stop="toggleFullscreen">✕</button>
      <img :src="activeContent" :alt="activeTabName" />
    </div>
    
    <!-- Onglet docs: deux pages -->
    <div v-if="activeTab === 'docs'" class="docs-container">
      <div class="docs-tabs">
        <button :class="{active: docsPage === 'sources'}" @click="docsPage = 'sources'">Sources</button>
        <button :class="{active: docsPage === 'methodo'}" @click="docsPage = 'methodo'">Méthodologie</button>
      </div>
      <div class="docs-content">
        <img v-if="docsPage === 'sources'" src="/femmes-quais/source-3.png" alt="Sources" />
        <img v-else src="/femmes-quais/source-4.png" alt="Méthodologie" />
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'FemmesQuaisView',
  data() {
    return {
      activeTab: 'carte1',
      fullscreen: false,
      docsPage: 'sources',
      tabs: [
            { 
              id: 'carte1', 
              name: 'Jour', 
              icon: '☀️',
              content: '/femmes-quais/carte-1.png'
            },
            { 
              id: 'carte2', 
              name: 'Nuit', 
              icon: '🌙',
              content: '/femmes-quais/carte-2.png'
            },
            { 
              id: 'docs', 
              name: 'Sources & Méthodo', 
              icon: '📚',
              content: null
            }
          ]
    }
  },
  computed: {
    activeContent() {
      const tab = this.tabs.find(t => t.id === this.activeTab)
      if (!tab) return null
      if (tab.id === 'docs') return null
      return tab.content
    },
    activeTabName() {
      const tab = this.tabs.find(t => t.id === this.activeTab)
      return tab ? tab.name : ''
    }
}
  ,
  methods: {
    toggleFullscreen() {
      this.fullscreen = !this.fullscreen
    }
  }
}
</script>

<style scoped>
.femmes-quais-page {
  display: flex;
  height: 100vh;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  overflow: hidden;
}

.sidebar {
  width: 300px;
  background: white;
  padding: 30px 20px;
  box-shadow: 2px 0 10px rgba(0, 0, 0, 0.1);
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.back {
  align-self: flex-start;
  background: #2C7A7B;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.back:hover {
  background: #234e52;
  transform: translateX(-4px);
}

.sidebar h1 {
  font-size: 1.8rem;
  color: #2d3748;
  margin: 0;
  line-height: 1.3;
}

.project-info {
  background: #f7fafc;
  padding: 15px;
  border-radius: 8px;
  border-left: 4px solid #2C7A7B;
}

.project-info p {
  margin: 0;
  color: #4a5568;
  font-size: 0.95rem;
  line-height: 1.5;
}

hr {
  border: none;
  border-top: 1px solid #e2e8f0;
  margin: 10px 0;
}

.tabs {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.tab-btn {
  width: 100%;
  padding: 12px 16px;
  background: #f7fafc;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  color: #4a5568;
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: left;
}

.tab-btn:hover {
  background: #edf2f7;
  border-color: #cbd5e0;
}

.tab-btn.active {
  background: #2C7A7B;
  border-color: #2C7A7B;
  color: white;
  font-weight: 600;
}

.content-container {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
  overflow: auto;
}

.image-viewer {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  max-width: 100%;
  max-height: 100%;
}

.main-image {
  max-width: 100%;
  max-height: calc(100vh - 160px);
  object-fit: contain;
  border-radius: 12px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
  cursor: zoom-in;
  transition: transform 0.3s ease;
}

.main-image:hover {
  transform: scale(1.02);
}

.image-caption {
  font-size: 1.1rem;
  color: #2d3748;
  font-weight: 600;
  text-align: center;
  background: white;
  padding: 12px 24px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 20px;
  color: #718096;
  text-align: center;
}

.empty-state p {
  font-size: 1.2rem;
  margin: 0;
}

.fullscreen-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.95);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  cursor: zoom-out;
  padding: 20px;
}

.fullscreen-modal img {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
  box-shadow: 0 0 50px rgba(255, 255, 255, 0.1);
}

.close-btn {
  position: fixed;
  top: 20px;
  right: 20px;
  background: white;
  color: #2d3748;
  border: none;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  font-size: 24px;
  font-weight: bold;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  transition: all 0.3s ease;
  z-index: 1001;
}

.close-btn:hover {
  background: #f7fafc;
  transform: scale(1.1);
}

.docs-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 20px;
}
.docs-tabs { display: flex; gap: 8px; }
.docs-tabs button { padding: 8px 12px; border-radius: 6px; border: 1px solid #e2e8f0; background: #f7fafc; cursor: pointer; }
.docs-tabs button.active { background: #2C7A7B; color: #fff; border-color: #2C7A7B; }
.docs-content img { max-width: 100%; max-height: calc(100vh - 220px); object-fit: contain; border-radius: 8px; box-shadow: 0 6px 20px rgba(0,0,0,0.2); }

@media (max-width: 768px) {
  .femmes-quais-page {
    flex-direction: column;
  }

  .sidebar {
    width: 100%;
    max-height: 40vh;
  }

  .sidebar h1 {
    font-size: 1.4rem;
  }

  .content-container {
    padding: 20px;
  }

  .main-image {
    max-height: calc(60vh - 100px);
  }
}
</style>
