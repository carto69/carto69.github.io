<template>
  <div id="app">
    <main>
      <MenuView v-if="activeTab === 'home'" @open="openTab" />
      <div v-if="activeTab === 'velov'" class="scene">
        <VelovView @back="goHome" />
      </div>
      <div v-if="activeTab === 'velib'" class="scene">
        <VelibView @back="goHome" />
      </div>
      <div v-if="activeTab === 'velo13'" class="scene">
        <Velo13View @back="goHome" />
      </div>
      <div v-if="activeTab === 'mapelia'" class="scene">
        <MapeliaView @back="goHome" />
      </div>
      <div v-if="activeTab === 'xplore'" class="scene">
        <XploreMap @back="goHome" />
      </div>
      <div v-if="activeTab === 'femmes-quais'" class="scene">
        <FemmesQuaisView @back="goHome" />
      </div>
      <div v-if="activeTab === 'zonzon'" class="scene">
        <ZonzonView @back="goHome" />
      </div>
      <div v-if="activeTab === 'portfolio'" class="scene">
        <PortfolioView @back="goHome" />
      </div>
      <div v-if="activeTab === 'dashboard-r'" class="scene">
        <DashboardRView @back="goHome" />
      </div>
      <div v-if="activeTab === 'sontla'" class="scene">
        <SontlaMap @back="goHome" />
      </div>
    </main>
  </div>
</template>

<script>
import MenuView from './components/MenuView.vue'
import XploreMap from './components/XploreMap.vue'
import MapView from './components/MapView.vue'
import VelovView from './components/VelovView.vue'
import VelibView from './components/VelibView.vue'
import Velo13View from './components/Velo13View.vue'
import MapeliaView from './components/MapeliaView.vue'
import FemmesQuaisView from './components/FemmesQuaisView.vue'
import ZonzonView from './components/ZonzonView.vue'
import PortfolioView from './components/PortfolioView.vue'
import PloufMap from './components/PloufMap.vue'
import DashboardRView from './components/DashboardRView.vue'
import SontlaMap from './components/SontlaMap.vue'

export default {
  components: { MenuView, XploreMap, MapView, VelovView, VelibView, Velo13View, MapeliaView, FemmesQuaisView, ZonzonView, PortfolioView, PloufMap, DashboardRView, SontlaMap },
  data() {
    return {
      activeTab: 'home'
    }
  },
  mounted() {
    // Gérer le bouton retour du navigateur
    window.addEventListener('popstate', this.handlePopState)
    // Initialiser l'historique
    this.updateHistory()
  },
  beforeUnmount() {
    window.removeEventListener('popstate', this.handlePopState)
  },
  methods: {
    openTab(tab) {
      if ([
        'velov', 'velib', 'velo13', 'mapelia', 'xplore', 'sontla',
        'femmes-quais', 'zonzon', 'portfolio', 'dashboard-r'
      ].includes(tab)) {
        this.activeTab = tab
        this.updateHistory()
      } else {
        this.activeTab = 'home'
        this.updateHistory()
      }
    },
    goHome() {
      this.activeTab = 'home'
      this.updateHistory()
    },
    updateHistory() {
      const url = this.activeTab === 'home' ? '/' : `/#${this.activeTab}`
      window.history.pushState({ tab: this.activeTab }, '', url)
    },
    handlePopState(event) {
      if (event.state && event.state.tab) {
        this.activeTab = event.state.tab
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
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif !important;
}

main {
  width: 100%;
  height: 100%;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif !important;
}

.scene {
  width: 100%;
  height: 100%;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif !important;
}
</style>
