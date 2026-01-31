<template>
  <div class="maplibre-wrapper">
    <div ref="mapContainer" class="maplibre-map"></div>

    <div class="top-controls">
      <button class="back-btn" @click="$emit('back')">← Accueil</button>
      <div class="title-and-btn">
        <button class="title-btn">son la</button>
        <button class="add-pin-btn" @click="startPinSelection" title="Ajouter un pin">+</button>
      </div>
    </div>

    <div v-if="isSelecting && selectionStep === 'location'" class="selecting-overlay"></div>
    <div v-if="showModal" class="modal-overlay" @click.self="closePinModal">
      <div class="modal">
        <h3>{{ selectionStep === 'location' ? 'Cliquez sur la carte pour sélectionner le lieu' : 'nouveau marqueur' }}</h3>
        <div v-if="selectionStep === 'emoji'" class="emoji-selector">
          <label>symbole :</label>
          <div class="emoji-grid">
            <button
              v-for="emoji in emojis"
              :key="emoji"
              :class="['emoji-btn', { selected: selectedEmoji === emoji }]"
              @click="selectedEmoji = emoji"
            >
              {{ emoji }}
            </button>
          </div>
        </div>

        <div v-if="selectionStep === 'emoji'" class="text-input">
          <label>commentaire :</label>
          <input
            v-model="pinText"
            type="text"
            placeholder="Ajouter un texte..."
            maxlength="100"
          >
        </div>

        <div v-if="selectionStep === 'emoji'" class="modal-actions">
          <button class="btn-cancel" @click="closePinModal">Annuler</button>
          <button class="btn-confirm" @click="confirmPin">Confirmer</button>
        </div>

        <div v-else class="modal-actions">
          <button class="btn-cancel" @click="closePinModal">Annuler</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'

const mapContainer = ref(null)
let map = null
let pinnedCoordinates = null

const showModal = ref(false)
const isSelecting = ref(false)
const selectedEmoji = ref('📍')
const pinText = ref('')
const selectionStep = ref('location')
const emojis = ['📍', '🏠', '🚗', '🏪', '🚔', '🚒', '🚨', '☀️']
const pins = ref([])

const loadPins = () => {
  const saved = localStorage.getItem('sonla-pins')
  if (saved) {
    pins.value = JSON.parse(saved)
  }
}

const savePins = () => {
  localStorage.setItem('sonla-pins', JSON.stringify(pins.value))
}

const startPinSelection = () => {
  isSelecting.value = true
  selectionStep.value = 'location'
}

const mapClickHandler = async (e) => {
  if (!isSelecting.value) return

  pinnedCoordinates = e.lngLat
  selectionStep.value = 'emoji'
  selectedEmoji.value = '📍'
  pinText.value = ''
  isSelecting.value = false
  showModal.value = true
}

const closePinModal = () => {
  showModal.value = false
  pinnedCoordinates = null
  isSelecting.value = false
  selectionStep.value = 'location'
}

const confirmPin = async () => {
  if (!pinnedCoordinates) return

  try {
    const response = await fetch(
      `https://nominatim.openstreetmap.org/reverse?format=json&lat=${pinnedCoordinates.lat}&lon=${pinnedCoordinates.lng}`
    )
    const data = await response.json()
    const address = data.address?.road || data.address?.hamlet || data.address?.village || 'Localisation inconnue'
    const pin = {
      id: Date.now(),
      coordinates: [pinnedCoordinates.lng, pinnedCoordinates.lat],
      emoji: selectedEmoji.value,
      text: pinText.value,
      address: address,
      timestamp: new Date().toLocaleString('fr-FR')
    }

    pins.value.push(pin)
    savePins()
    addPinToMap(pin)
  } catch (error) {
    console.error('Erreur lors de la géolocalisation:', error)
  }

  closePinModal()
}

const deletePin = (pinId) => {
  pins.value = pins.value.filter(p => p.id !== pinId)
  savePins()
  location.reload()
}

const addPinToMap = (pin) => {
  const el = document.createElement('div')
  el.className = 'map-pin'
  el.innerHTML = pin.emoji
  el.style.cursor = 'pointer'

  const popup = new maplibregl.Popup({ offset: 25 })
    .setHTML(`
      <div class="pin-popup">
        <div class="pin-emoji">${pin.emoji}</div>
        <div class="pin-address">${pin.address}</div>
        ${pin.text ? `<div class="pin-text">${pin.text}</div>` : ''}
        <div class="pin-time">${pin.timestamp}</div>
        <button class="pin-delete-btn" onclick="window.deletePinGlobal(${pin.id})">supprimer</button>
      </div>
    `)

  new maplibregl.Marker({ element: el })
    .setLngLat(pin.coordinates)
    .setPopup(popup)
    .addTo(map)
}

window.deletePinGlobal = (pinId) => {
  deletePin(pinId)
}

onMounted(() => {
  map = new maplibregl.Map({
    container: mapContainer.value,
    projection: 'equalEarth',
    style: {
      version: 8,
      sources: {
        osm: {
          type: 'raster',
          tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
          tileSize: 256,
          attribution: '© OpenStreetMap contributors'
        }
      },
      layers: [
        {
          id: 'osm-layer',
          type: 'raster',
          source: 'osm',
          paint: {
            'raster-opacity': 0.85,
            'raster-saturation': -0.8,
            'raster-brightness-min': 0.2,
            'raster-brightness-max': 0.95
          }
        }
      ],
      background: {
        paint: {
          'background-color': '#ffffff'
        }
      }
    },
    center: [2.3522, 48.8566],
    zoom: 5
  })

  map.addControl(new maplibregl.ScaleControl({
    maxWidth: 200,
    unit: 'metric'
  }))

  map.on('click', mapClickHandler)

  loadPins()
  pins.value.forEach(pin => addPinToMap(pin))
})

onBeforeUnmount(() => {
  if (map) map.remove()
})
</script>

<style scoped>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

.maplibre-wrapper {
  position: relative;
  width: 100%;
  height: 100vh;
  overflow: hidden;
}

.maplibre-map {
  width: 100%;
  height: 100%;
}

.top-controls {
  position: absolute;
  top: 24px;
  left: 24px;
  right: 24px;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  z-index: 10;
}

.back-btn {
  padding: 8px 16px;
  background: #fff;
  color: #222;
  border: 1px solid #ddd;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 600;
  transition: all 0.2s ease;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.back-btn:hover {
  background: #f5f5f5;
  border-color: #999;
}

.title-and-btn {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 12px;
}

.title-btn {
  padding: 10px 18px;
  background: #000;
  color: white;
  font-size: 28px;
  font-weight: bold;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  font-family: "Courier New", Courier, monospace;
  letter-spacing: -1px;
  transition: all 0.2s ease;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.title-btn:hover {
  background: #333;
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.3);
}

.add-pin-btn {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  background: #333;
  color: white;
  border: none;
  font-size: 28px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
  transition: all 0.2s ease;
}

.add-pin-btn:hover {
  background: #000;
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.3);
  transform: scale(1.1);
}

.add-pin-btn:active {
  transform: scale(0.95);
}

.selecting-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.15);
  z-index: 500;
  cursor: crosshair;
  pointer-events: none;
  border: 8px solid #000;
  box-sizing: border-box;
}

.modal-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: white;
  border-radius: 12px;
  padding: 30px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  max-width: 400px;
  width: 90%;
  animation: slideUp 0.3s ease;
}

@keyframes slideUp {
  from {
    transform: translateY(40px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.modal h3 {
  margin-bottom: 20px;
  color: #333;
  font-size: 20px;
}

.emoji-selector {
  margin-bottom: 20px;
}

.emoji-selector label {
  display: block;
  margin-bottom: 10px;
  font-weight: 600;
  color: #555;
}

.emoji-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 8px;
}

.emoji-btn {
  padding: 10px;
  border: 2px solid #ddd;
  background: white;
  border-radius: 8px;
  font-size: 24px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.emoji-btn:hover {
  border-color: #333;
  transform: scale(1.1);
}

.emoji-btn.selected {
  border-color: #333;
  background: #f0f0f0;
}

.text-input {
  margin-bottom: 20px;
}

.text-input label {
  display: block;
  margin-bottom: 8px;
  font-weight: 600;
  color: #555;
}

.text-input input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 14px;
  transition: border-color 0.2s ease;
}

.text-input input:focus {
  outline: none;
  border-color: #333;
}

.modal-actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
}

.btn-cancel,
.btn-confirm {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-cancel {
  background: #f0f0f0;
  color: #333;
}

.btn-cancel:hover {
  background: #e0e0e0;
}

.btn-confirm {
  background: #333;
  color: white;
}

.btn-confirm:hover {
  background: #000;
}

:global(.map-pin) {
  font-size: 20px;
  cursor: pointer;
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.2));
  transition: all 0.2s ease;
}

:global(.map-pin:hover) {
  filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.3));
  transform: scale(1.2);
}

:global(.maplibregl-popup-content) {
  padding: 12px !important;
  border-radius: 8px;
}

.pin-popup {
  min-width: 200px;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.pin-emoji {
  font-size: 24px;
  margin-bottom: 8px;
}

.pin-address {
  font-weight: 600;
  color: #333;
  margin-bottom: 6px;
  font-size: 13px;
}

.pin-text {
  color: #666;
  margin-bottom: 6px;
  font-size: 13px;
  font-style: italic;
}

.pin-time {
  color: #999;
  font-size: 11px;
  margin-bottom: 8px;
}

.pin-delete-btn {
  width: 100%;
  padding: 8px 12px;
  background: #ff4444;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.pin-delete-btn:hover {
  background: #cc0000;
}

:global(.maplibregl-ctrl-scale) {
  background: white !important;
  border: 1px solid #ddd !important;
  border-radius: 4px !important;
}
</style>
