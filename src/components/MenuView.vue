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
  background-position: center 20%;
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
  color: #000;
  font-size: 0.9rem;
  font-weight: 400;
  text-shadow: none;
  background: rgba(255, 255, 255, 0.7);
  padding: 6px 12px;
  border-radius: 4px;
  z-index: 10;
}

.hero::after {
  content: 'Kunyu Wanguo Quantu, Matteo Ricci, 1602.';
  position: absolute;
  bottom: 20px;
  right: 30px;
  color: #000;
  font-size: 0.85rem;
  font-style: italic;
  text-shadow: none;
  background: rgba(255, 255, 255, 0.7);
  padding: 6px 12px;
  border-radius: 4px;
  z-index: 10;
}

.title {
  font-size: 5rem;
  font-weight: 700;
  color: #4CAF50;
  text-shadow: none;
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
  padding: 24px 20px;
  border-radius: 12px;
  background: rgba(56, 142, 60, 0.65);
  backdrop-filter: blur(10px);
  border: none;
  cursor: pointer;
  min-width: 240px;
  max-width: 280px;
  transition: all 0.3s ease;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

.tile:hover {
  transform: translateY(-8px);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
  background: rgba(56, 142, 60, 0.8);
}

.tile-icon {
  font-size: 2.5rem;
  margin-bottom: 8px;
  text-align: center;
}

.tile h2 {
  margin: 0 0 8px 0;
  color: white;
  font-size: 1.5rem;
  font-weight: 600;
  text-align: center;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.4);
}

.tile p {
  margin: 0 0 16px 0;
  color: rgba(255, 255, 255, 0.95);
  font-size: 13px;
  line-height: 1.4;
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
