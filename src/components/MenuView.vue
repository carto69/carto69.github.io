<template>
  <main class="menu-landing">
    <div class="map-background"></div>
    <div class="content-overlay">
      <div class="hero">
        <h1 class="brand">carto69</h1>
      </div>

      <div class="project-grid">
        <article class="project-tile" @click="$emit('open', 'italie2')" role="button" tabindex="0">
          <div class="project-icon">🗺️</div>
          <h2>Italie 2</h2>
          <p>Plan interactif du centre commercial multi-étages</p>
          <div class="project-cta">Explorer →</div>
        </article>

        <article class="project-tile coming">
          <div class="project-icon">🚀</div>
          <h2>Nouveaux projets</h2>
          <p>Bientôt disponible</p>
          <div class="project-cta disabled">À venir</div>
        </article>
      </div>
    </div>
  </main>
</template>

<script>
export default {
  name: 'MenuView'
}
</script>

<style scoped>
.menu-landing {
  min-height: 100vh;
  position: relative;
  overflow: hidden;
}

.map-background {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-image: url('/vintage-map.jpg');
  background-size: cover;
  background-position: center;
}

.content-overlay {
  position: relative;
  z-index: 1;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
}

.hero {
  text-align: center;
  margin-bottom: 60px;
  animation: fadeIn 0.8s ease-out;
}

.brand {
  font-family: Arial, sans-serif;
  font-size: 80px;
  font-weight: bold;
  color: #4a7c3a;
  margin: 0;
  letter-spacing: -2px;
  text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
}

.project-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 20px;
  max-width: 700px;
  width: 100%;
}

.project-tile {
  background: rgba(90, 140, 75, 0.75);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255,255,255,0.3);
  padding: 24px;
  border-radius: 12px;
  cursor: pointer;
  box-shadow: 0 6px 24px rgba(0,0,0,0.15);
  display: flex;
  flex-direction: column;
  gap: 10px;
  transition: all 0.3s ease;
  animation: fadeInUp 0.8s ease-out;
}

.project-tile:hover {
  transform: translateY(-4px);
  box-shadow: 0 10px 36px rgba(0,0,0,0.2);
}

.project-tile.coming {
  opacity: 0.65;
  cursor: default;
}

.project-tile.coming:hover {
  transform: none;
}

.project-icon {
  font-size: 40px;
  margin-bottom: 6px;
}

.project-tile h2 {
  font-size: 20px;
  margin: 0;
  color: #fff;
  font-weight: 700;
}

.project-tile p {
  color: rgba(255,255,255,0.9);
  font-size: 13px;
  line-height: 1.5;
  margin: 0;
  flex-grow: 1;
}

.project-cta {
  margin-top: 12px;
  align-self: flex-start;
  background: rgba(70, 110, 60, 0.75);
  color: #fff;
  padding: 10px 20px;
  border-radius: 8px;
  font-weight: 600;
  font-size: 13px;
  transition: all 0.3s ease;
}

.project-tile:hover .project-cta:not(.disabled) {
  transform: translateX(4px);
}

.project-cta.disabled {
  background: rgba(100, 100, 100, 0.65);
  cursor: not-allowed;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
