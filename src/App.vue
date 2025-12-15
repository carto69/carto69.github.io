<template>
  <div id="app">
    <main>
      <MenuView v-if="activeTab === 'home'" @open="openTab" />
      <div v-if="activeTab === 'italie2'" class="scene">
        <MapView @back="goHome" />
      </div>
      <div v-if="activeTab === 'velov'" class="scene">
        <VelovView @back="goHome" />
      </div>
      <div v-if="activeTab === 'velib'" class="scene">
        <VelibView @back="goHome" />
      </div>
      <div v-if="activeTab === 'mapelia'" class="scene">
        <MapeliaView @back="goHome" />
      </div>
    </main>
  </div>
</template>

<script>
import MenuView from './components/MenuView.vue'
import MapView from './components/MapView.vue'
import VelovView from './components/VelovView.vue'
import VelibView from './components/VelibView.vue'
import MapeliaView from './components/MapeliaView.vue'

export default {
  components: { MenuView, MapView, VelovView, VelibView, MapeliaView },
  data() {
    return {
      activeTab: 'home'
    }
  },
  mounted() {
    // Restaurer l'état depuis l'URL au chargement
    const hash = window.location.hash.slice(1)
    if (hash && ['italie2', 'velov', 'velib', 'mapelia'].includes(hash)) {
      this.activeTab = hash
    }

    // Écouter les changements d'historique (bouton retour)
    window.addEventListener('popstate', this.handlePopState)
  },
  beforeUnmount() {
    window.removeEventListener('popstate', this.handlePopState)
  },
  methods: {
    openTab(tab) {
      if (tab === 'italie2' || tab === 'velov' || tab === 'velib' || tab === 'mapelia') {
        this.activeTab = tab
        window.history.pushState({ tab }, '', `#${tab}`)
      } else {
        this.activeTab = 'home'
        window.history.pushState({ tab: 'home' }, '', '#')
      }
    },
    goHome() {
      this.activeTab = 'home'
      window.history.pushState({ tab: 'home' }, '', '#')
    },
    handlePopState(event) {
      // Gérer le bouton retour du navigateur
      const hash = window.location.hash.slice(1)
      if (hash && ['italie2', 'velov', 'velib', 'mapelia'].includes(hash)) {
        this.activeTab = hash
      } else {
        this.activeTab = 'home'
      }
    }
  }
}
</script>

<style scoped>
#app {
  width: 100%;
  height: 100vh;
  overflow: hidden;
}

main {
  width: 100%;
  height: 100%;
}

.scene {
  width: 100%;
  height: 100%;
}
</style>
