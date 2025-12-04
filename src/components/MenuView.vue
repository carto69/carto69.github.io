<template>
  <main class="menu">
    <div class="tiles">
      <article class="tile" @click="$emit('open', 'italie2')">
        <h2>Italie 2</h2>
        <p>Plan interactif du centre commercial</p>
      </article>
      <article class="tile" @click="$emit('open', 'velov')">
        <h2>69 en velo'v</h2>
        <p>Visualisation de vos trajets VeloV</p>
      </article>
    </div>
  </main>
</template>

<script>
export default { name: 'MenuView' }
</script>

<style scoped>
.menu { padding: 40px; }
.tiles { display: flex; gap: 12px; flex-wrap: wrap; }
.tile { padding: 24px; border-radius: 8px; background: white; border: 1px solid rgba(0,0,0,0.06); cursor: pointer; min-width: 200px; }
.tile:hover { box-shadow: 0 2px 12px rgba(0,0,0,0.1); }
.tile h2 { margin: 0 0 8px 0; color: #333; }
.tile p { margin: 0; color: #666; font-size: 14px; }
</style>
