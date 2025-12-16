<template>
  <main class="menu">
    <div class="credits-toggle top-right" @click="showCredits = !showCredits">Crédit</div>
    <div v-if="showCredits" class="credits-panel">
      <div class="credit-line"><strong>Source carte:</strong> Kunyu Wanguo Quantu (Matteo Ricci, 1602)</div>
      <div class="credit-line"><strong>Crédit:</strong> Elia Terragni</div>
    </div>
    <div class="hero">
      <h1 class="title">carto69</h1>
      <div class="tiles">
        <article class="tile" @click="$emit('open', 'zonzon')">
          <div class="tile-icon">🌍</div>
          <h2>zonzon</h2>
          <button class="tile-btn">Explorer →</button>
        </article>
        <article class="tile" @click="openMapelia">
          <div class="tile-icon">🗺️</div>
          <h2>Mapelia</h2>
          <button class="tile-btn">Explorer →</button>
        </article>
        <article class="tile" @click="$emit('open', 'portfolio')">
          <div class="tile-icon">📁</div>
          <h2>Autres projets</h2>
          <button class="tile-btn">Explorer →</button>
        </article>
        <div class="tile-break"></div>
        <article class="tile" @click="$emit('open', 'italie2')">
          <div class="tile-icon">🗺️</div>
          <h2>Italie 2</h2>
          <button class="tile-btn">Explorer →</button>
        </article>
        <article class="tile" @click="$emit('open', 'velov')">
          <div class="tile-icon">🚴</div>
          <h2>69 en velo'v</h2>
          <button class="tile-btn">Explorer →</button>
        </article>
        <article class="tile" @click="$emit('open', 'velib')">
          <div class="tile-icon">🚲</div>
          <h2>75 en vélib'</h2>
          <button class="tile-btn">Explorer →</button>
        </article>
        <article class="tile" @click="$emit('open', 'femmes-quais')">
          <div class="tile-icon">👥</div>
          <h2>Genre et espace public</h2>
          <button class="tile-btn">Explorer →</button>
        </article>
      </div>
    </div>
    
  </main>
</template>

<script>
export default {
  name: 'MenuView',
  methods: {
    openMapelia() {
      const code = prompt('Code d\'accès requis :')
      if (code === '1612') {
        this.$emit('open', 'mapelia')
      } else if (code !== null) {
        alert('Code incorrect')
      }
    }
  },
  data() {
    return {
      showCredits: false
    }
  }
}
</script>

<style scoped>
.menu {
  position: relative;
  width: 100%;
  height: 100vh;
  overflow: hidden;
  background: url('/vintage-map.jpg') no-repeat;
  background-size: 130% auto; /* zoom plus fort pour rogner en haut et à droite */
  background-position: 45% -20px; /* décale vers la gauche et monte pour éliminer la ligne noire */
}

.credits-top {
  position: fixed;
  top: 20px;
  right: 30px;
  color: #000;
  font-size: 0.75rem;
  font-weight: 400;
  background: rgba(255, 255, 255, 0.7);
  padding: 6px 10px;
  border-radius: 4px;
  z-index: 100;
  white-space: nowrap;
}

.top-right {
  position: fixed;
  top: 20px;
  right: 20px;
}

.credits-toggle {
  background: rgba(255, 255, 255, 0.85);
  color: #2d3748;
  padding: 8px 12px;
  border-radius: 6px;
  font-size: 0.8rem;
  cursor: pointer;
  z-index: 101;
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
}
.credits-toggle:hover { background: white; }

.credits-panel {
  position: fixed;
  top: 60px;
  right: 20px;
  background: rgba(255, 255, 255, 0.9);
  color: #2d3748;
  padding: 10px 12px;
  border-radius: 6px;
  font-size: 0.8rem;
  z-index: 101;
  box-shadow: 0 4px 16px rgba(0,0,0,0.25);
}
.credit-line { white-space: nowrap; }

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
  font-style: italic;
}

.tiles {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  justify-content: center;
  max-width: 900px;
}

.tile-break {
  width: 100%;
  flex-basis: 100%;
  height: 0;
}

.tile {
  position: relative;
  padding: 10px 8px;
  border-radius: 8px;
  background: rgba(46, 125, 50, 0.22); /* vert océan cohérent */
  backdrop-filter: blur(10px);
  border: none;
  cursor: pointer;
  min-width: 130px;
  max-width: 160px;
  transition: all 0.3s ease;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

.tile:hover {
  transform: translateY(-8px);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
  background: rgba(46, 125, 50, 0.45);
}

.tile-icon {
  font-size: 1.4rem;
  margin-bottom: 4px;
  text-align: center;
}

.tile h2 {
  margin: 0 0 5px 0;
  color: white;
  font-size: 0.95rem;
  font-weight: 600;
  text-align: center;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.4);
}

.tile p {
  margin: 0 0 8px 0;
  color: rgba(255, 255, 255, 0.92);
  font-size: 9px;
  line-height: 1.2;
  text-align: center;
  text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.3);
}

.tile-btn {
  width: 100%;
  padding: 8px;
  background: rgba(255, 255, 255, 0.9);
  color: #2C5F2D;
  border: none;
  border-radius: 6px;
  font-size: 12px;
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
