<template>
  <div class="dashboard-r-container">
    <button class="back-btn" @click="$emit('back')">← Retour</button>
    <iframe 
      :src="dashboardUrl"
      title="Dashboard R COMOVE"
      allowfullscreen
      allow="fullscreen"
    ></iframe>
  </div>
</template>

<script>
export default {
  name: "DashboardRView",
  emits: ["back"],
  data() {
    return {
      dashboardUrl: "https://gesukri.shinyapps.io/dashboardr_bateliers_eliaterragni/"
    }
  },
  mounted() {
    document.title = "Dashboard R - Enquête COMOVE Strasbourg"
  },
  beforeUnmount() {
    document.title = "carto69"
  }
}
</script>

<style scoped>
.dashboard-r-container {
  width: 100%;
  height: 100vh;
  position: relative;
  display: flex;
}

.back-btn {
  position: absolute;
  top: 20px;
  right: 20px;
  z-index: 1000;
  padding: 10px 20px;
  background: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 1rem;
  font-weight: 600;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
}

.back-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
}

iframe {
  width: 100%;
  height: 100%;
  border: none;
}
</style>
