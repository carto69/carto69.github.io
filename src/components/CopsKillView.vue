<template>
  <div class="copskill-view">
    <button class="back-btn" @click="$emit('back')">← Retour</button>
    <div class="content">
      <h1>Cops Kill</h1>
      <p>Projet en construction...</p>
    </div>
  </div>
</template>

<script>
export default {
  name: 'CopsKillView',
  emits: ['back'],
  mounted() {
    document.title = 'Cops Kill - carto69'
  },
  beforeUnmount() {
    document.title = 'carto69'
  }
}
</script>

<style scoped>
.copskill-view {
  width: 100%;
  height: 100vh;
  position: relative;
  background: #1a1a1a;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
}

.back-btn {
  position: absolute;
  top: 20px;
  right: 20px;
  z-index: 1000;
  padding: 10px 20px;
  background: white;
  border: 2px solid #0f172a;
  border-radius: 10px;
  cursor: pointer;
  font-size: 1rem;
  font-weight: 600;
  color: #0f172a;
  box-shadow: 0 4px 12px rgba(15,23,42,0.15);
  transition: all 0.3s ease;
}

.back-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(15,23,42,0.25);
}

.content {
  text-align: center;
  padding: 40px;
}

.content h1 {
  font-size: 3rem;
  margin-bottom: 20px;
  font-weight: 700;
}

.content p {
  font-size: 1.2rem;
  opacity: 0.8;
}
</style>
