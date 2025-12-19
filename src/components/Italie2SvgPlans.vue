<template>
  <div class="italie2-svg-plans">
    <div v-for="(floor, key) in floors" :key="key" class="svg-floor-block">
      <h3>{{ floor.name }}</h3>
      <svg :width="svgWidth" :height="svgHeight" :viewBox="`0 0 ${svgWidth} ${svgHeight}`">
        <rect x="0" y="0" :width="svgWidth" :height="svgHeight" fill="#f5f5f5" stroke="#bbb" />
        <g v-for="(store, idx) in floor.stores" :key="store.id">
          <rect
            :x="storeX(idx, floor.stores.length)"
            :y="storeY(idx, floor.stores.length)"
            :width="boxWidth"
            :height="boxHeight"
            :fill="colorForFloor(key)"
            stroke="#888"
            rx="8"
          />
          <text
            :x="storeX(idx, floor.stores.length) + boxWidth / 2"
            :y="storeY(idx, floor.stores.length) + boxHeight / 2 + 5"
            text-anchor="middle"
            font-size="13"
            fill="#222"
            style="font-family: 'Space Grotesk', Arial, sans-serif;"
          >
            {{ store.name }}
          </text>
        </g>
        <text
          v-if="!floor.stores.length"
          :x="svgWidth/2"
          :y="svgHeight/2"
          text-anchor="middle"
          font-size="18"
          fill="#aaa"
        >
          Aucun magasin
        </text>
      </svg>
    </div>
  </div>
</template>

<script>
import floorsData from '../../public/sens-italie-deux/floors-data.json'

export default {
  name: 'Italie2SvgPlans',
  data() {
    return {
      svgWidth: 600,
      svgHeight: 320,
      boxWidth: 120,
      boxHeight: 40,
      floors: floorsData.floors
    }
  },
  methods: {
    storeX(idx, total) {
      // Répartit les magasins en ligne, centrés
      const margin = 20
      const perRow = Math.floor(this.svgWidth / (this.boxWidth + margin))
      const row = Math.floor(idx / perRow)
      const col = idx % perRow
      const totalCols = Math.min(perRow, total)
      const offsetX = (this.svgWidth - (totalCols * (this.boxWidth + margin) - margin)) / 2
      return offsetX + col * (this.boxWidth + margin)
    },
    storeY(idx, total) {
      const margin = 20
      const perRow = Math.floor(this.svgWidth / (this.boxWidth + margin))
      const row = Math.floor(idx / perRow)
      return 40 + row * (this.boxHeight + margin)
    },
    colorForFloor(key) {
      if (key === 'floor1') return '#b3e5fc'
      if (key === 'floor2') return '#c8e6c9'
      if (key === 'floor3') return '#ffe082'
  
      return '#fff'
    }
  }
}
</script>

<style scoped>
.italie2-svg-plans {
  display: flex;
  flex-wrap: wrap;
  gap: 32px;
  justify-content: center;
}
.svg-floor-block {
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
  padding: 18px 24px;
  min-width: 640px;
}
svg {
  margin-top: 8px;
  background: #f5f5f5;
  border-radius: 8px;
}
</style>
