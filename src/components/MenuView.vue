<template>
  <main class="menu">
    <div class="hero">
      <h1 class="title">carto69</h1>
      <div class="tiles">
        <article class="tile" @click="$emit('open', 'italie2')">
          <div class="tile-icon">🗺️</div>
          <h2>Italie 2</h2>
          <p>Plan interactif du centre commercial multi-étages</p>
          <button class="tile-btn">Explorer →</button>
        </article>
        <article class="tile" @click="$emit('open', 'velov')">
          <div class="tile-icon">🚴</div>
          <h2>69 en velo'v</h2>
          <p>Carte de mes itinéraires Vélo'V à Lyon</p>
          <button class="tile-btn">Explorer →</button>
        </article>
        <article class="tile" @click="$emit('open', 'zonzon')">
          <div class="tile-icon">🌍</div>
          <h2>zonzon</h2>
          <p>Carte mondiale en projection Equal Earth</p>
          <button class="tile-btn">Explorer →</button>
        </article>
      </div>
    </div>
  </main>
</template>

<script>
export default { name: 'MenuView' }
</script>

<style scoped>
.menu {
  position: relative;
  width: 100%;
  height: 100vh;
  overflow: hidden;
  background: url('/vintage-map.jpg') center/cover no-repeat;
}

.hero {
  position: relative;
  z-index: 2;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  padding: 40px 20px;
}

.hero::before {
  content: 'E. Terragni';
  position: absolute;
  top: 20px;
  right: 30px;
  color: rgba(255, 255, 255, 0.7);
  font-size: 1.1rem;
  font-weight: 500;
  text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.5);
}

.hero::after {
  content: 'Kunyu Wanguo Quantu, Matteo Ricci, 1602.';
  position: absolute;
  bottom: 20px;
  right: 30px;
  color: rgba(255, 255, 255, 0.6);
  font-size: 0.9rem;
  font-style: italic;
  text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.5);
}

.title {
  font-size: 5rem;
  font-weight: 700;
  color: #4CAF50;
  text-shadow: 3px 3px 6px rgba(0, 0, 0, 0.5);
  margin: 0 0 60px 0;
  font-family: 'Arial Black', sans-serif;
  letter-spacing: 3px;
}

.tiles {
  display: flex;
  gap: 24px;
  flex-wrap: wrap;
  justify-content: center;
  max-width: 1200px;
}

.tile {
  position: relative;
  padding: 32px 28px;
  border-radius: 12px;
  background: rgba(76, 175, 80, 0.7);
  backdrop-filter: blur(10px);
  border: none;
  cursor: pointer;
  min-width: 280px;
  max-width: 320px;
  transition: all 0.3s ease;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

.tile:hover {
  transform: translateY(-8px);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
  background: rgba(76, 175, 80, 0.85);
}

.tile-icon {
  font-size: 3rem;
  margin-bottom: 12px;
  text-align: center;
}

.tile h2 {
  margin: 0 0 12px 0;
  color: white;
  font-size: 1.8rem;
  font-weight: 600;
  text-align: center;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.4);
}

.tile p {
  margin: 0 0 20px 0;
  color: rgba(255, 255, 255, 0.95);
  font-size: 15px;
  line-height: 1.5;
  text-align: center;
  text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.3);
}

.tile-btn {
  width: 100%;
  padding: 12px;
  background: rgba(255, 255, 255, 0.9);
  color: #2C5F2D;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.tile-btn:hover {
  background: white;
  transform: scale(1.02);
}

@media (max-width: 768px) {
  .title {
    font-size: 3rem;
  }
  .tiles {
    flex-direction: column;
    align-items: center;
  }
  .tile {
    max-width: 100%;
  }
  .hero::before,
  .hero::after {
    font-size: 0.8rem;
    right: 15px;
  }
}
</style>
