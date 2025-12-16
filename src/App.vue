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
      <div v-if="activeTab === 'femmes-quais'" class="scene">
        <FemmesQuaisView @back="goHome" />
      </div>
      <div v-if="activeTab === 'zonzon'" class="scene">
        <ZonzonView @back="goHome" />
      </div>
      <div v-if="activeTab === 'portfolio'" class="scene">
        <PortfolioView @back="goHome" />
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
import FemmesQuaisView from './components/FemmesQuaisView.vue'
import ZonzonView from './components/ZonzonView.vue'
import PortfolioView from './components/PortfolioView.vue'

export default {
  components: { MenuView, MapView, VelovView, VelibView, MapeliaView, FemmesQuaisView, ZonzonView, PortfolioView },
  data() {
    return {
      activeTab: 'home'
    }
  },
  methods: {
    openTab(tab) {
      if (tab === 'italie2' || tab === 'velov' || tab === 'velib' || tab === 'mapelia' || tab === 'femmes-quais' || tab === 'zonzon' || tab === 'portfolio') {
        this.activeTab = tab
      } else {
        this.activeTab = 'home'
      }
    },
    goHome() {
      this.activeTab = 'home'
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
