<template>
  <main class="menu home-bg">
    <div class="credits-toggle top-right" @click="showCredits = !showCredits">crédit</div>
    <div v-if="showCredits" class="credits-panel next-to-toggle">
      <div class="credit-line">Elia Terragni</div>
      <div class="credit-line"><a href="mailto:elia.terragni@proton.me">elia.terragni@proton.me</a><br>0652213579</div>
      <div class="credit-line">Source carte : Kunyu Wanguo Quantu (Matteo Ricci, 1602)</div>
    </div>
    <button class="portfolio-toggle bottom-left" @click="$emit('open', 'portfolio')">Autres<br>cartes</button>
    <button class="photos-toggle bottom-left-above" @click="$emit('open', 'photos')">Photos</button>
    <div class="hero">
      <h1 class="title" style="font-size:6rem; letter-spacing: -2px;">carto69</h1>
      <div class="tiles double-row">
        <!-- Ligne 1 (5 tuiles) -->
        <div class="tiles-row">
          <article class="tile" @click="openMapelia">
            <h2><span class="tile-title">mapelia</span></h2>
            <button class="tile-btn">→</button>
          </article>
          <article class="tile" @click="$emit('open', 'sontla')">
            <h2>son la</h2>
            <button class="tile-btn">→</button>
          </article>
          <article class="tile" @click="$emit('open', 'xplore')">
            <h2>xplore</h2>
            <button class="tile-btn">→</button>
          </article>
          <article class="tile" @click="$emit('open', 'zonzon')">
            <h2>zonzon</h2>
            <button class="tile-btn">→</button>
          </article>
          <article class="tile" @click="$emit('open', 'copskill')">
            <h2>cops kill</h2>
            <button class="tile-btn">→</button>
          </article>
        </div>
        <!-- Ligne 2 (5 tuiles) -->
        <div class="tiles-row">
          <article class="tile" @click="$emit('open', 'dashboard-r')">
            <h2>dashboard R<br> Strasbourg</h2>
            <button class="tile-btn">→</button>
          </article>
          <article class="tile" @click="$emit('open', 'velov')">
            <h2>69 en velov</h2>
            <button class="tile-btn">→</button>
          </article>
          <article class="tile" @click="$emit('open', 'velo13')">
            <h2>13 en vélo</h2>
            <button class="tile-btn">→</button>
          </article>
          <article class="tile" @click="$emit('open', 'velib')">
            <h2>75 en velib</h2>
            <button class="tile-btn">→</button>
          </article>
          <article class="tile" @click="$emit('open', 'femmes-quais')">
            <h2>genre et espace public</h2>
            <button class="tile-btn">→</button>
          </article>
        </div>
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
html, body {
  margin: 0 !important;
  padding: 0 !important;
  overflow: hidden !important;
  width: 100%;
  height: 100%;
  position: fixed;
}

/* Bouton Photos en haut à gauche, couleur rose Canada */
.photos-toggle.top-left {
  position: fixed;
  top: 20px;
  left: 30px;
  color: #111;
  font-size: 0.9rem;
  font-weight: 700;
  background: #e5bb8cff;
  border: 1px solid #111;
  box-shadow: 0 0 0 1px #111;
  padding: 4px 12px;
  border-radius: 8px;
  z-index: 101;
  white-space: nowrap;
  cursor: pointer;
  font-family: "Courier New", Courier, monospace;
  transition: background 0.2s, color 0.2s;
}
.photos-toggle.top-left:hover {
  background: #f3e0c7;
  color: #b89c6c;
}

/* Bouton Photos au-dessus du bouton Autres cartes */
.photos-toggle.bottom-left-above {
  position: fixed;
  bottom: 100px;
  left: 30px;
  color: #2d7d4d;
  font-size: 0.9rem;
  font-weight: 700;
  background: #e5bb8cff;
  border: 2px solid #2d7d4d;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  padding: 6px 14px;
  border-radius: 8px;
  z-index: 100;
  white-space: nowrap;
  cursor: pointer;
  font-family: "Courier New", Courier, monospace;
  transition: all 0.2s ease;
}

.photos-toggle.bottom-left-above:hover {
  background: #f3e0c7;
  border-color: #4a9f6d;
  transform: scale(1.05);
}

/* Bouton Portfolio/Autres cartes en bas à gauche */
.portfolio-toggle.bottom-left {
  position: fixed;
  bottom: 30px;
  left: 30px;
  color: #2d7d4d;
  font-size: 0.9rem;
  font-weight: 700;
  line-height: 1.3;
  text-align: center;
  background: #e5bb8cff;
  border: 2px solid #2d7d4d;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  padding: 8px 16px;
  border-radius: 8px;
  z-index: 100;
  cursor: pointer;
  font-family: "Courier New", Courier, monospace;
  transition: all 0.2s ease;
}

.portfolio-toggle.bottom-left:hover {
  background: #f3e0c7;
  border-color: #4a9f6d;
  transform: scale(1.05);
}


      .home-bg {
        position: fixed;
        top: 0;
        left: 0;
        min-height: 100vh;
        min-width: 100vw;
        width: 100vw;
        height: 100vh;
        background: #e6f0fa url('/vintage-map-compressed.jpg') center 0px no-repeat;
        background-size: cover;
        opacity: 1 !important;
        z-index: 0;
        margin: 0;
        padding: 0;
        overflow: hidden;
      }
.menu {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  padding: 0;
  margin: 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.hero {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.credits-toggle.top-right {
  position: fixed;
  top: 20px;
  right: 30px;
    color: #7fa46a;
    font-size: 0.9rem;
    font-weight: 700;
    background: rgb(244, 228, 160);
    border: 1px solid #7fa46a;
    box-shadow: 0 0 0 1px #7fa46a;
    padding: 4px 12px;
    border-radius: 8px;
    z-index: 100;
    white-space: nowrap;
    cursor: pointer;
  font-family: "Courier New", Courier, monospace;
}

/* Affichage du panneau à côté du bouton crédit */
.credits-panel.next-to-toggle {
  position: fixed;
  top: 20px;
  right: 170px;
  margin-left: 0;
}

.credits-panel {
  box-shadow: 0 0 0 1px #7fa46a, 0 2px 16px #0002;
  background: rgb(244, 228, 160);
  color: #222;
  min-width: unset;
  max-width: unset;
  width: auto;
    padding: 10px 18px 8px 18px;
    font-size: 0.85rem;
  z-index: 9999;
  position: fixed;
  top: 120px;
  right: 30px;
  display: block;
  border-radius: 12px;
  box-sizing: border-box;
}
.credit-line { 
  color: #222;
  font-size: 0.85rem;
  margin-bottom: 4px;
  white-space: nowrap; 
  display: block;
  font-family: inherit;
}
.title {
  font-size: 16rem;
  font-weight: 700;
  color: #7fa46a;
  text-shadow: -2px -2px 0 #E8D4A0, 2px -2px 0 #E8D4A0, -2px 2px 0 #E8D4A0, 2px 2px 0 #E8D4A0;
  margin: 0 0 40px 0;
  font-family: "Courier New", Courier, monospace;
  letter-spacing: 7px;
  font-style: normal;
  text-align: center;
}
.hero .tiles.double-row {
  display: flex;
  flex-direction: column;
  gap: 18px 0;
  margin-top: 20px;
  max-width: 900px;
  width: 100%;
  align-items: center;
}
.tiles-row {
  display: flex;
  flex-direction: row;
  justify-content: center;
  gap: 24px;
  width: 100%;
}
.hero .tile {
  background: rgba(127, 164, 106, 0.85);
  border-radius: 18px;
  box-shadow: 0 0 0 2px #E8D4A0, 0 2px 8px #E8D4A0;
  padding: 15px 10px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
  width: 140px;
  min-width: 120px;
  max-width: 180px;
  height: 90px;
  border: none;
  box-sizing: border-box;
  opacity: 0.92;
}
.hero .tile h2 {
  font-size: 1.1rem;
  margin: 0;
  font-weight: 700;
  letter-spacing: -1px;
  text-align: center;
  text-transform: none;
  color: rgb(244, 228, 160);
  line-height: 1.1;
  font-family: "Courier New", Courier, monospace;
}
.tile-btn {
  color: #7fa46a;
  background: rgb(244, 228, 160);
  border: none;
  border-radius: 8px;
  font-size: 20px;
  font-weight: 600;
  cursor: pointer;
  margin-top: 4px;
  padding: 0 18px;
  transition: background 0.2s, transform 0.2s;
}
.tile-btn .arrow {
  font-size: 3em;
  color: #7fa46a;
}
.tile-btn:hover {
  background: #fffbe6;
  color: #7fa46a;
  transform: scale(1.05);
}
.credits-panel {
  box-shadow: 0 0 0 1px #7fa46a, 0 2px 16px #0002;
  background: rgb(244, 228, 160);
  color: #222;
  min-width: unset;
  max-width: unset;
  width: auto;
  padding: 16px 28px 12px 28px;
  font-size: 1rem;
  z-index: 9999;
  position: fixed;
  top: 120px;
  right: 30px;
  display: block;
  border-radius: 12px;
  box-sizing: border-box;
}
.tile-icon {
  font-size: 1.4rem;
  margin-bottom: 4px;
  text-align: center;
  color: #E8D4A0;
}
.arrow {
  font-size: 3em;
  color: #E8D4A0;
}
.tile p {
  margin: 0 0 8px 0;
  color: #4a5568;
  font-size: 10px;
  line-height: 1.25;
  text-align: center;
}

.sontla-btn {
  position: relative;
  padding: 6px 14px;
  background: #e5bb8cff;
  color: #2d7d4d;
  border: 2px solid #2d7d4d;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  font-family: "Courier New", Courier, monospace;
  white-space: nowrap;
}

.sontla-btn:hover {
  background: #f3e0c7;
  border-color: #4a9f6d;
  transform: scale(1.05);
}

.sontla-btn:active {
  transform: scale(0.95);
}

@media (max-width: 768px) {
  .title {
    font-size: 3rem;
  }
  .hero .tiles {
    flex-direction: column;
    align-items: center;
  }
  .hero .tile {
    max-width: 100%;
  }
  .credits-toggle,
  .credits-panel {
    right: 10px;
    left: auto;
  }
  .sontla-btn {
    bottom: 20px;
    right: 20px;
    padding: 8px 14px;
    font-size: 12px;
  }
}
</style>
