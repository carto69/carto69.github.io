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
          <button class="tile-btn">→</button>
        </article>
        <article class="tile" @click="openMapelia">
          <div class="tile-icon">🗺️</div>
          <h2>Mapelia</h2>
          <button class="tile-btn">→</button>
        </article>
        <article class="tile" @click="$emit('open', 'portfolio')">
          <div class="tile-icon">📁</div>
          <h2>Autres projets</h2>
          <button class="tile-btn">→</button>
        </article>
        <div class="tile-break"></div>
        <article class="tile" @click="$emit('open', 'italie2')">
          <div class="tile-icon">🗺️</div>
          <h2>Italie 2</h2>
          <button class="tile-btn">→</button>
        </article>
        <article class="tile" @click="$emit('open', 'velov')">
          <div class="tile-icon">🚴</div>
          <h2>69 en velo'v</h2>
          <button class="tile-btn">→</button>
        </article>
        <article class="tile" @click="$emit('open', 'velib')">
          <div class="tile-icon">🚲</div>
          <h2>75 en vélib'</h2>
          <button class="tile-btn">→</button>
        </article>
        <article class="tile" @click="$emit('open', 'femmes-quais')">
          <div class="tile-icon">👥</div>
          <h2>Genre et espace public</h2>
          <button class="tile-btn">→</button>
        </article>
      </div>
    </div>
    
  </main>
</template>

<script>
export default {
  name: 'MenuView',
  emits: ['open'],
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
  background-size: 105% auto; /* léger dézoom */
  background-position: 100% -20px; /* décale très légèrement à droite */
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
  background: #F4E4A0; /* jaune beige plus doux */
  color: #2d3748;
  padding: 8px 12px;
  border-radius: 6px;
  font-size: 0.8rem;
  cursor: pointer;
  z-index: 101;
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
}
.credits-toggle:hover { background: #EED08C; }

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

.tiles {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 18px 22px;
  max-width: 820px;
}

.tile-btn {
  width: 100%;
  padding: 8px;
  background: #F4E4A0; /* jaune beige pour les onglets */
  color: #2d3748;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}
.tile-btn:hover {
  background: #EED08C; /* hover légèrement plus sombre */
  transform: scale(1.02);
}

.title {
  font-size: 5rem;
  font-weight: 700;
  color: #2e7ba8; /* bleu légèrement plus foncé */
  text-shadow: -1px -1px 0 #E8D4A0, 1px -1px 0 #E8D4A0, -1px 1px 0 #E8D4A0, 1px 1px 0 #E8D4A0;
  margin: 0 0 60px 0;
  font-family: 'Arial Black', sans-serif;
  letter-spacing: 3px;
  font-style: normal;
}

.tile-break {
  width: 100%;
  flex-basis: 100%;
  height: 0;
}

.tile {
  position: relative;
  padding: 12px 10px;
  border-radius: 10px;
  background: rgba(214, 239, 247, 0.92); /* bleu clair pour l'onglet */
  border: 1px solid rgba(58, 143, 191, 0.25); /* liseré bleu */
  cursor: pointer;
  min-width: 130px;
  max-width: 170px;
  transition: all 0.25s ease;
  box-shadow: 0 6px 18px rgba(0, 0, 0, 0.25);
}

.tile:hover {
  transform: translateY(-6px);
  box-shadow: 0 10px 28px rgba(0, 0, 0, 0.35);
  background: rgba(198, 232, 243, 0.92);
}

.tile-icon {
  font-size: 1.4rem;
  margin-bottom: 4px;
  text-align: center;
}

.tile h2 {
  margin: 0 0 6px 0;
  color: #2d3748;
  font-size: 1rem;
  font-weight: 700;
  text-align: center;
}

.tile p {
  margin: 0 0 8px 0;
  color: #4a5568;
  font-size: 10px;
  line-height: 1.25;
  text-align: center;
}

/* supprimé: doublon de tile-btn (version blanche) */

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
