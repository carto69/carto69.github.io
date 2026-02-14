<template>
  <main class="menu home-bg">
    <div class="credits-toggle bottom-right">crédit</div>
    <div class="credits-panel next-to-toggle-bottom">
      <div class="credit-line"><a href="mailto:elia.terragni@proton.me">elia.terragni@proton.me</a></div>
      <div class="credit-line">Source carte : Kunyu Wanguo Quantu (Matteo Ricci, 1602)</div>
    </div>
    <button class="portfolio-toggle bottom-left" @click="$emit('open', 'portfolio')">Autres<br>cartes</button>
    <button class="photos-toggle bottom-left-above" @click="$emit('open', 'photos')">Fotos</button>
    <div class="hero">
      <h1 class="title" style="font-size:6rem; letter-spacing: -2px;">cartopelo</h1>
      <div class="tiles double-row-vertical">
        <div class="tiles-row tiles-row-top">
          <article class="tile" @click="openMapelia">
            <h2><span class="tile-title big-title centered">mapelia</span></h2>
          </article>
          <article class="tile" @click="$emit('open', 'velov')">
            <h2><span class="tile-title big-title centered">le 69<br>en velov</span></h2>
          </article>
          <article class="tile" @click="$emit('open', 'velo13')">
            <h2><span class="tile-title big-title centered">le 13<br>en vélo</span></h2>
          </article>
          <article class="tile" @click="$emit('open', 'velib')">
            <h2><span class="tile-title big-title centered">le 75<br>en velib</span></h2>
          </article>
          <article class="tile" @click="$emit('open', 'femmes-quais')">
            <h2><span class="tile-title big-title centered">genre & espace public</span></h2>
          </article>
          <article class="tile" @click="$emit('open', 'dashboard-r')">
            <h2><span class="tile-title big-title centered">dashboard COMOVE Strasbourg</span></h2>
          </article>
        </div>
        <div class="tiles-row tiles-row-bottom">
          <article class="tile" @click="openZonzonExternal">
            <h2><span class="tile-title big-title centered">zonzon</span></h2>
          </article>

          <article class="tile" @click="$emit('open', 'abruler')">
            <h2><span class="tile-title big-title centered">à bruler</span></h2>
          </article>
          <article class="tile" @click="$emit('open', 'sontla')">
            <h2><span class="tile-title big-title centered">sont là</span></h2>
          </article>
          <article class="tile" @click="$emit('open', 'copskill')">
            <h2><span class="tile-title big-title centered">cops kill</span></h2>
          </article>
          <article class="tile" @click="$emit('open', 'xplore')">
            <h2><span class="tile-title big-title centered">xplore</span></h2>
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
    openZonzonExternal() {
      window.open('https://zonzon.vercel.app/', '_blank');
    }
  },
  methods: {
    openMapelia() {
      const code = prompt('Code d\'accès requis :')
      if (code === '1612') {
        this.$emit('open', 'mapelia')
      } else if (code !== null) {
        alert('Code incorrect')
      }
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
  transition: all 0.2s ease;  width: 90px;
  text-align: center;}

.photos-toggle.bottom-left-above:hover {
  background: #f3e0c7;
  border-color: #4a9f6d;
  transform: scale(1.05);
}

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
  width: 90px;
}

.portfolio-toggle.bottom-left:hover {
  background: #f3e0c7;
  border-color: #4a9f6d;
  transform: scale(1.12);
}

.home-bg {
  position: fixed;
  top: 0;
  left: 0;
  min-height: 100vh;
  min-width: 100vw;
  width: 100vw;
  height: 100vh;
  background: #e6f0fa url('/vintage-map-compressed.jpg') center -0px no-repeat;
  background-size: 112.5% auto !important; 
  background-position: center -20px !important;
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
  margin-top: 130px; 
}

.credits-toggle.bottom-right {
  position: fixed;
  bottom: 24px;
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

.credits-panel.next-to-toggle-bottom {
  position: fixed;
  right: 110px;
  bottom: 24px;
  top: auto;
  overflow: visible;
  border-radius: 10px;
  box-shadow: 0 4px 24px #0003, 0 0 0 1px #7fa46a;
  padding: 8px 14px;
  background: rgb(244, 228, 160);
  font-size: 1.05em;
  display: none;
  opacity: 0;
  pointer-events: none;
  z-index: 101;
  line-height: 1.5;
  box-sizing: border-box;
  height: auto !important;
  transition: opacity 0.2s;
}

.credits-toggle.bottom-right:hover + .credits-panel.next-to-toggle-bottom,
.credits-panel.next-to-toggle-bottom:hover {
  display: block !important;
  opacity: 1 !important;
  pointer-events: auto;
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

.tile-btn {
  color: #4caf50; 
  background: #ffe066; 
  border: none;
  border-radius: 50px;
  font-size: 18px;
  font-weight: 700;
  cursor: pointer;
  margin-top: 2px;
  padding: 2px 16px;
  transition: background 0.2s, transform 0.2s;
  box-shadow: 0 1px 4px #0001;
}
.tile-btn:hover {
  background: #fffbe6;
  color: #388e3c;
  transform: scale(1.08);
}


.tiles-row {
  display: flex;
  flex-direction: row;
  border: none;
  border-radius: 12px;
  width: max-content;
  margin-left: auto;
  margin-right: auto;
  margin-top: - 60px; 
}

.tiles-row + .tiles-row {
  margin-top: 32px;
}

.tile.break-after {
  flex-basis: 100%;
  width: 100%;
  max-width: 100%;
  margin-bottom: 0;
}

.hero .tile {
  background: rgba(127, 164, 106, 0.85);
  border-radius: 14px;
  box-shadow: 0 0 0 2px #E8D4A0, 0 2px 8px #E8D4A0;
  padding: 3px 3px 2px 3px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: transform 0.18s cubic-bezier(.4,1.5,.5,1), box-shadow 0.18s cubic-bezier(.4,1.5,.5,1);
  width: 155px;
  min-width: 155px;
  max-width: 155px;
  height: 80px;
  border: none;
  box-sizing: border-box;
  opacity: 0.92;
  margin-bottom: 2px;
  position: relative;
}
.hero .tile h2 {
  font-size: 1.05rem;
  margin: 0;
  font-weight: 800;
  letter-spacing: 0.5px;
  text-align: center;
  text-transform: none;
  color: rgb(244, 228, 160);
  line-height: 1.2;
  font-family: "Courier New", Courier, monospace;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-wrap: wrap;
}
.hero .tile-btn {
  display: none;
}
.hero .tile-btn:hover {
  background: #fffbe6;
  color: #7fa46a;
  transform: scale(1.08);
}
.hero .tile:hover {
  transform: scale(1.07);
}

.tile-btn, .tile-btn:hover {
  transform: none !important;
  box-shadow: none !important;
}

.double-row-vertical {
  display: flex;
  flex-direction: column;
  align-items: center;
}
.tiles-row {
  display: flex;
  flex-direction: row;
  justify-content: center;
  gap: 16px;
  width: max-content;
}
.tiles-row-bottom {
  margin-top: 32px;
}

  .tile-btn {
    color: #7fa46a; 
    background: #E8D4A0; 
    border: none;
    border-radius: 50px;
    font-size: 18px;
    font-weight: 700;
    cursor: pointer;
    padding: 2px 16px;
    transition: background 0.2s, transform 0.2s;
    box-shadow: 0 1px 4px #0001;
  }
.tile-btn:hover {
  background: #fffbe6;
  color: #7fa46a;
  transform: scale(1.08);
}
.title {
  font-size: 8rem;
  font-weight: 700;
  color: #7fa46a;
  text-shadow: -2px -2px 0 #E8D4A0, 2px -2px 0 #E8D4A0, -2px 2px 0 #E8D4A0, 2px 2px 0 #E8D4A0;
  margin: 60px 0 24px 0; 
  font-family: "Courier New", Courier, monospace;
  letter-spacing: 7px;
  font-style: normal;
  text-align: center;
}

.sontla-btn {
  position: fixed;
  bottom: 80px;
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