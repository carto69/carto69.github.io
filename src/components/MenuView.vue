<template>
  <main class="menu">
    <div class="credits-top">Elia Terragni</div>
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
        <article class="tile" @click="$emit('open', 'velib')">
          <div class="tile-icon">🚲</div>
          <h2>75 en vélib'</h2>
          <p>Carte de mes itinéraires Vélib' à Paris</p>
          <button class="tile-btn">Explorer →</button>
        </article>
        <article class="tile" @click="$emit('open', 'mapelia')">
          <div class="tile-icon">🗺️</div>
          <h2>Mapelia</h2>
          <p>Carte interactive avec parcours personnalisables</p>
          <button class="tile-btn">Explorer →</button>
        </article>
        <article class="tile" @click="$emit('open', 'femmes-quais')">
          <div class="tile-icon">👥</div>
          <h2>Femmes sur les quais</h2>
          <p>Cartes sensibles</p>
          <button class="tile-btn">Explorer →</button>
        </article>
        <article class="tile" @click="$emit('open', 'zonzon')">
          <div class="tile-icon">🌍</div>
          <h2>zonzon</h2>
          <p>Carte mondiale en projection Equal Earth</p>
          <button class="tile-btn">Explorer →</button>
        </article>
        <article class="tile" @click="$emit('open', 'portfolio')">
          <div class="tile-icon">📁</div>
          <h2>Autres projets</h2>
          <p>Portfolio de cartes et projets cartographiques</p>
          <button class="tile-btn">Explorer →</button>
        </article>
      </div>
    </div>
    <div class="credits-bottom">Kunyu Wanguo Quantu, Matteo Ricci, 1602.</div>
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
  background-position: center 70%;
}

.credits-top {
  position: fixed;
  top: 20px;
  right: 30px;
  color: #000;
  font-size: 0.95rem;
  font-weight: 400;
  background: rgba(255, 255, 255, 0.75);
  padding: 8px 14px;
  border-radius: 4px;
  z-index: 100;
  white-space: nowrap;
}

.credits-bottom {
  position: fixed;
  bottom: 20px;
  right: 30px;
  color: #000;
  font-size: 0.9rem;
  font-style: italic;
  background: rgba(255, 255, 255, 0.75);
  padding: 8px 14px;
  border-radius: 4px;
  z-index: 100;
  white-space: nowrap;
  text-align: right;
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

.title {
  font-size: 5rem;
  font-weight: 700;
  color: #2C7A7B;
  text-shadow: none;
  margin: 0 0 60px 0;
  font-family: 'Arial Black', sans-serif;
  letter-spacing: 3px;
}

.tiles {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
  justify-content: center;
  max-width: 1000px;
}

.tile {
  position: relative;
  padding: 20px 18px;
  border-radius: 12px;
  background: rgba(44, 122, 123, 0.25);
  backdrop-filter: blur(10px);
  border: none;
  cursor: pointer;
  min-width: 200px;
  max-width: 240px;
  transition: all 0.3s ease;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

.tile:hover {
  transform: translateY(-8px);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
  background: rgba(44, 122, 123, 0.5);
}

.tile-icon {
  font-size: 2.2rem;
  margin-bottom: 6px;
  text-align: center;
}

.tile h2 {
  margin: 0 0 6px 0;
  color: white;
  font-size: 1.3rem;
  font-weight: 600;
  text-align: center;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.4);
}

.tile p {
  margin: 0 0 12px 0;
  color: rgba(255, 255, 255, 0.95);
  font-size: 12px;
  line-height: 1.3;
  text-align: center;
  text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.3);
}

.tile-btn {
  width: 100%;
  padding: 10px;
  background: rgba(255, 255, 255, 0.9);
  color: #2C5F2D;
  border: none;
  border-radius: 8px;
  font-size: 14px;
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
  .credits-top,
  .credits-bottom {
    font-size: 0.8rem;
    right: 15px;
  }
}
</style>
