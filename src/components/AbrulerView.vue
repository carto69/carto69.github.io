<template>
  <div class="abruler-container">
    <iframe 
      src="/abruler/index.html" 
      class="abruler-iframe"
      frameborder="0"
      seamless>
    </iframe>
  </div>
</template>

<script>
export default {
  name: 'AbrulerView'
}
</script>

<style scoped>
.abruler-container {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.abruler-iframe {
  width: 100%;
  height: 100%;
  border: none;
}
</style>
