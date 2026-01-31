<template>
  <div class="cracarte-container">
    <button class="back-button" @click="$emit('back')" title="Retour à l'accueil">← Accueil</button>
    <iframe src="/cracarte/index.html" class="cracarte-iframe"></iframe>
  </div>
</template>

<script>
export default {
  name: 'CracarteView'
}
</script>

<style scoped>
.cracarte-container {
  position: relative;
  width: 100%;
  height: 100vh;
  background: #000;
}

.cracarte-iframe {
  width: 100%;
  height: 100%;
  border: none;
}

.back-button {
  position: absolute;
  top: 12px;
  left: 12px;
  background: #000;
  color: #e74c3c;
  border: 2px solid #8B0000;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.16);
  z-index: 1000;
  transition: all 0.2s ease;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

.back-button:hover {
  background: #8B0000;
  box-shadow: 0 3px 10px rgba(0,0,0,0.18);
  transform: translateY(-1px);
}
</style>
