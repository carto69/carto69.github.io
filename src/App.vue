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
    </main>
  </div>
</template>

<script>
import MenuView from './components/MenuView.vue'
import MapView from './components/MapView.vue'
import VelovView from './components/VelovView.vue'

export default {
  components: { MenuView, MapView, VelovView },
  data() {
    return {
      activeTab: 'home'
    }
  },
  methods: {
    openTab(tab) {
      if (tab === 'italie2' || tab === 'velov') {
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
