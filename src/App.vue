<template>
  <div id="app">
    <LoginView v-if="!isAuthenticated" @authenticated="handleAuthenticated" />
    <main v-else>
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
      <div v-if="activeTab === 'copskill'" class="scene">
        <CopsKillView @back="goHome" />
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
      <div v-if="activeTab === 'abruler'" class="scene">
        <CracarteView @back="goHome" />
      </div>
    </main>
  </div>
</template>

<script>
import LoginView from './components/LoginView.vue'
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
import DashboardRView from './components/DashboardRView.vue'
import SontlaMap from './components/SontlaMap.vue'
import CracarteView from './components/CracarteView.vue'
import CopsKillView from './components/CopsKillView.vue'

export default {
  components: { LoginView, MenuView, XploreMap, MapView, VelovView, VelibView, Velo13View, MapeliaView, FemmesQuaisView, ZonzonView, PortfolioView, DashboardRView, SontlaMap, CracarteView, CopsKillView },
  data() {
    return {
      activeTab: 'home',
      isAuthenticated: false
    }
  },
  mounted() {
    localStorage.removeItem('carto69_authenticated')
    localStorage.removeItem('carto69_user')
    this.checkAuthentication()
    window.addEventListener('popstate', this.handlePopState)
    this.updateHistory()
  },
  beforeUnmount() {
    window.removeEventListener('popstate', this.handlePopState)
  },
  methods: {
    checkAuthentication() {
      const auth = localStorage.getItem('carto69_authenticated')
      this.isAuthenticated = auth === 'true'
    },
    handleAuthenticated() {
      this.isAuthenticated = true
    },
    openTab(tab) {
      if ([
        'velov', 'velib', 'velo13', 'mapelia', 'xplore', 'sontla',
        'femmes-quais', 'zonzon', 'abruler', 'copskill', 'portfolio', 'dashboard-r'
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

<style>
:global(html), :global(body) {
  margin: 0;
  padding: 0;
}
</style>

<style scoped>
#app {
  width: 100%;
  height: 100vh;
  overflow: hidden;
  margin: 0;
  padding: 0;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif !important;
}

main {
  width: 100%;
  height: 100%;
  margin: 0;
  padding: 0;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif !important;
}

.scene {
  width: 100%;
  height: 100%;
  margin: 0;
  padding: 0;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif !important;
}
</style>
