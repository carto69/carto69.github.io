<template>
  <main class="menu-landing">
    <div class="map-background"></div>
    <div class="content-overlay">
      <div class="hero">
        <h1 class="brand">carto69</h1>
        <p class="tagline">Cartographie interactive & visualisations géospatiales</p>
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
  font-size: 72px;
  font-weight: 800;
  background: linear-gradient(135deg, #fff 0%, #f0f0ff 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin: 0;
  letter-spacing: -2px;
  text-shadow: 0 4px 20px rgba(0,0,0,0.1);
  filter: drop-shadow(0 2px 8px rgba(0,0,0,0.3));
}

.tagline {
  color: rgba(255,255,255,0.95);
  font-size: 18px;
  margin-top: 12px;
  font-weight: 300;
  text-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.project-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 24px;
  max-width: 900px;
  width: 100%;
}

.project-tile {
  background: rgba(255,255,255,0.98);
  backdrop-filter: blur(15px);
  border: 1px solid rgba(255,255,255,0.4);
  padding: 32px;
  border-radius: 16px;
  cursor: pointer;
  box-shadow: 0 8px 32px rgba(0,0,0,0.15);
  display: flex;
  flex-direction: column;
  gap: 12px;
  transition: all 0.3s ease;
  animation: fadeInUp 0.8s ease-out;
}

.project-tile:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 48px rgba(0,0,0,0.2);
}

.project-tile.coming {
  opacity: 0.7;
  cursor: default;
}

.project-tile.coming:hover {
  transform: none;
}

.project-icon {
  font-size: 48px;
  margin-bottom: 8px;
}

.project-tile h2 {
  font-size: 24px;
  margin: 0;
  color: #333;
  font-weight: 700;
}

.project-tile p {
  color: #666;
  font-size: 14px;
  line-height: 1.6;
  margin: 0;
  flex-grow: 1;
}

.project-cta {
  margin-top: 16px;
  align-self: flex-start;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  transition: all 0.3s ease;
}

.project-tile:hover .project-cta:not(.disabled) {
  transform: translateX(4px);
}

.project-cta.disabled {
  background: #ccc;
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
