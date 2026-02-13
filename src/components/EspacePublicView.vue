<template>
  <div class="espace-public-container">
    <button class="back-button" @click="$emit('back')" title="Retour à l'accueil">← Accueil</button>
    <div class="content">
      <h1>Espace Public</h1>
    </div>
  </div>
</template>

<script>
export default {
  name: 'EspacePublicView'
}
</script>

<style scoped>
.espace-public-container {
  position: relative;
  width: 100%;
  height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

.content {
  text-align: center;
  color: #fff;
}

.content h1 {
  font-size: 3rem;
  margin: 0 0 1rem 0;
}

.content p {
  font-size: 1.5rem;
}

.back-button {
  position: absolute;
  top: 12px;
  left: 12px;
  background: #fff;
  color: #111;
  border: 1px solid #111;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.16);
  z-index: 10;
  transition: all 0.2s ease;
  font-family: 'Space Grotesk', 'Hermes-Grotesk', 'Hermes Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

.back-button:hover {
  background: #f4f4f4;
  box-shadow: 0 3px 10px rgba(0,0,0,0.18);
  transform: translateY(-1px);
}
</style>
