<template>
  <div class="mapelia-page">
    <aside class="mapelia-controls">
      <button class="back" @click="$emit('back')">← Retour</button>
      <h1>Mapelia</h1>
      
      <div v-if="isLocked" class="lock-screen">
        <div class="lock-icon">🔒</div>
        <p>Cette carte est protégée par mot de passe</p>
        <form @submit.prevent="unlock">
          <input 
            type="password" 
            v-model="passwordInput" 
            placeholder="Mot de passe"
            class="password-input"
            autofocus
          />
          <button type="submit" class="btn">Déverrouiller</button>
        </form>
      </div>

      <div v-else class="controls">
        <hr />

        <div class="marker-tools">
          <h3>Ajouter un marqueur</h3>
          <p class="instruction">Cliquez sur la carte pour placer un marqueur</p>
          
          <div class="marker-config">
            <label>
              Type de symbole
              <select v-model="newMarker.symbol">
                <option value="pin">📍 Pin</option>
                <option value="star">⭐ Étoile</option>
                <option value="circle">⚫ Cercle</option>
                <option value="square">⬛ Carré</option>
                <option value="triangle">🔺 Triangle</option>
                <option value="heart">❤️ Cœur</option>
                <option value="flag">🚩 Drapeau</option>
              </select>
            </label>

            <label>
              Couleur
              <input type="color" v-model="newMarker.color" />
            </label>

            <label>
              Titre
              <input 
                type="text" 
                v-model="newMarker.title" 
                placeholder="Nom du lieu"
                maxlength="50"
              />
            </label>

            <label>
              Commentaire
              <textarea 
                v-model="newMarker.comment" 
                placeholder="Description, notes..."
                rows="3"
                maxlength="500"
              ></textarea>
            </label>
          </div>
        </div>

        <hr />

        <div class="marker-list" v-if="markers.length > 0">
          <h3>Marqueurs ({{ markers.length }})</h3>
          <div class="scroll-container">
            <div 
              v-for="marker in markers" 
              :key="marker.id"
              class="marker-item"
              @click="selectMarker(marker)"
              :class="{ active: selectedMarker?.id === marker.id }"
            >
              <div class="marker-header">
                <span class="marker-symbol" :style="{ color: marker.color }">
                  {{ getSymbolIcon(marker.symbol) }}
                </span>
                <strong>{{ marker.title || 'Sans titre' }}</strong>
              </div>
              <small v-if="marker.comment" class="marker-comment">
                {{ truncate(marker.comment, 60) }}
              </small>
              <div class="marker-actions">
                <button class="btn-icon" @click.stop="editMarker(marker)" title="Modifier">
                  ✏️
                </button>
                <button class="btn-icon" @click.stop="deleteMarker(marker.id)" title="Supprimer">
                  🗑️
                </button>
              </div>
            </div>
          </div>
        </div>

        <hr />

        <div class="data-tools">
          <h3>Données</h3>
          <button class="btn" @click="exportMarkers">Exporter JSON</button>
          <label class="btn file-label">
            Importer JSON
            <input type="file" accept="application/json" @change="importMarkers" />
          </label>
          <button class="btn btn-danger" @click="clearAllMarkers">Tout effacer</button>
        </div>
      </div>
    </aside>

    <div ref="mapContainer" class="map-container" v-show="!isLocked"></div>
    <div v-if="isLocked" class="map-placeholder">
      <div class="placeholder-content">
        <div class="lock-icon-large">🔒</div>
        <p>Entrez le mot de passe pour accéder à la carte</p>
      </div>
    </div>

    <!-- Modal d'édition -->
    <div v-if="editingMarker" class="modal-overlay" @click.self="cancelEdit">
      <div class="modal">
        <h2>Modifier le marqueur</h2>
        
        <label>
          Type de symbole
          <select v-model="editingMarker.symbol">
            <option value="pin">📍 Pin</option>
            <option value="star">⭐ Étoile</option>
            <option value="circle">⚫ Cercle</option>
            <option value="square">⬛ Carré</option>
            <option value="triangle">🔺 Triangle</option>
            <option value="heart">❤️ Cœur</option>
            <option value="flag">🚩 Drapeau</option>
          </select>
        </label>

        <label>
          Couleur
          <input type="color" v-model="editingMarker.color" />
        </label>

        <label>
          Titre
          <input 
            type="text" 
            v-model="editingMarker.title" 
            placeholder="Nom du lieu"
            maxlength="50"
          />
        </label>

        <label>
          Commentaire
          <textarea 
            v-model="editingMarker.comment" 
            placeholder="Description, notes..."
            rows="5"
            maxlength="500"
          ></textarea>
        </label>

        <div class="modal-actions">
          <button class="btn" @click="saveEdit">Enregistrer</button>
          <button class="btn btn-secondary" @click="cancelEdit">Annuler</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
const mapboxgl = window.mapboxgl

export default {
  name: 'MapeliaView',
  data() {
    return {
      isLocked: true,
      passwordInput: '',
      map: null,
      markers: [],
      mapMarkers: [], // Instances Mapbox des marqueurs
      selectedMarker: null,
      editingMarker: null,
      newMarker: {
        symbol: 'pin',
        color: '#FF5733',
        title: '',
        comment: ''
      }
    }
  },
  mounted() {
    // Vérifier si déjà déverrouillé dans la session
    if (sessionStorage.getItem('mapeliaUnlocked') === 'true') {
      this.isLocked = false
    }
    
    const token = import.meta.env.VITE_MAPBOX_TOKEN
    if (token && !this.isLocked) {
      mapboxgl.accessToken = token
      this.initMap()
    }
    if (!this.isLocked) {
      this.loadMarkers()
    }
  },
  beforeUnmount() {
    if (this.map) {
      this.map.remove()
    }
  },
  methods: {
    initMap() {
      this.map = new mapboxgl.Map({
        container: this.$refs.mapContainer,
        style: 'mapbox://styles/mapbox/streets-v12',
        projection: 'equalEarth', // Projection Equal Earth (proche authalic)
        center: [8.5, 45.5], // Entre France et Italie (Alpes)
        zoom: 5
      })

      this.map.on('load', () => {
        // Gestionnaire de clic pour ajouter des marqueurs
        this.map.on('click', (e) => {
          this.addMarker(e.lngLat)
        })

        // Charger les marqueurs existants
        this.renderMarkers()
      })

      this.map.addControl(new mapboxgl.NavigationControl())
      this.map.addControl(new mapboxgl.ScaleControl({ unit: 'metric' }), 'bottom-right')
    },

    addMarker(lngLat) {
      const marker = {
        id: Date.now(),
        lng: lngLat.lng,
        lat: lngLat.lat,
        symbol: this.newMarker.symbol,
        color: this.newMarker.color,
        title: this.newMarker.title,
        comment: this.newMarker.comment
      }

      this.markers.push(marker)
      this.saveMarkers()
      this.renderMarker(marker)

      // Réinitialiser le formulaire (garder symbole et couleur)
      this.newMarker.title = ''
      this.newMarker.comment = ''
    },

    renderMarkers() {
      // Effacer les anciens marqueurs
      this.mapMarkers.forEach(m => m.remove())
      this.mapMarkers = []

      // Rendre tous les marqueurs
      this.markers.forEach(marker => {
        this.renderMarker(marker)
      })
    },

    renderMarker(marker) {
      // Créer l'élément SVG du marqueur
      const el = document.createElement('div')
      el.className = 'custom-marker'
      el.innerHTML = this.getMarkerSVG(marker.symbol, marker.color)
      el.style.cursor = 'pointer'

      // Créer le popup
      const popup = new mapboxgl.Popup({ offset: 25 }).setHTML(`
        <div style="color: #000; padding: 5px;">
          <strong style="color: ${marker.color}">${marker.title || 'Sans titre'}</strong>
          ${marker.comment ? `<p style="margin: 5px 0 0 0; font-size: 0.9em;">${marker.comment}</p>` : ''}
        </div>
      `)

      // Ajouter le marqueur à la carte
      const mapMarker = new mapboxgl.Marker(el)
        .setLngLat([marker.lng, marker.lat])
        .setPopup(popup)
        .addTo(this.map)

      this.mapMarkers.push(mapMarker)

      // Clic sur le marqueur
      el.addEventListener('click', () => {
        this.selectMarker(marker)
      })
    },

    getMarkerSVG(symbol, color) {
      const svgs = {
        pin: `<svg width="30" height="40" viewBox="0 0 30 40"><path d="M15 0C8.4 0 3 5.4 3 12c0 9 12 28 12 28s12-19 12-28c0-6.6-5.4-12-12-12z" fill="${color}" stroke="#000" stroke-width="2"/></svg>`,
        star: `<svg width="30" height="30" viewBox="0 0 30 30"><path d="M15 2l3.5 10.5H29l-9 6.5 3.5 10.5-9-6.5-9 6.5 3.5-10.5-9-6.5h10.5z" fill="${color}" stroke="#000" stroke-width="1.5"/></svg>`,
        circle: `<svg width="30" height="30" viewBox="0 0 30 30"><circle cx="15" cy="15" r="12" fill="${color}" stroke="#000" stroke-width="2"/></svg>`,
        square: `<svg width="30" height="30" viewBox="0 0 30 30"><rect x="3" y="3" width="24" height="24" fill="${color}" stroke="#000" stroke-width="2"/></svg>`,
        triangle: `<svg width="30" height="30" viewBox="0 0 30 30"><path d="M15 3L27 27H3z" fill="${color}" stroke="#000" stroke-width="2"/></svg>`,
        heart: `<svg width="30" height="30" viewBox="0 0 30 30"><path d="M15 27s-12-8-12-16c0-4 3-7 7-7 2 0 4 1 5 3 1-2 3-3 5-3 4 0 7 3 7 7 0 8-12 16-12 16z" fill="${color}" stroke="#000" stroke-width="1.5"/></svg>`,
        flag: `<svg width="30" height="40" viewBox="0 0 30 40"><path d="M5 5v30M5 5h18l-3 8 3 8H5" fill="${color}" stroke="#000" stroke-width="2"/></svg>`
      }
      return svgs[symbol] || svgs.pin
    },

    getSymbolIcon(symbol) {
      const icons = {
        pin: '📍',
        star: '⭐',
        circle: '⚫',
        square: '⬛',
        triangle: '🔺',
        heart: '❤️',
        flag: '🚩'
      }
      return icons[symbol] || '📍'
    },

    selectMarker(marker) {
      this.selectedMarker = marker
      this.map.flyTo({
        center: [marker.lng, marker.lat],
        zoom: 8,
        duration: 1000
      })
    },

    editMarker(marker) {
      this.editingMarker = { ...marker }
    },

    saveEdit() {
      const index = this.markers.findIndex(m => m.id === this.editingMarker.id)
      if (index !== -1) {
        this.markers[index] = this.editingMarker
        this.saveMarkers()
        this.renderMarkers()
      }
      this.editingMarker = null
    },

    cancelEdit() {
      this.editingMarker = null
    },

    deleteMarker(id) {
      if (confirm('Supprimer ce marqueur ?')) {
        this.markers = this.markers.filter(m => m.id !== id)
        this.saveMarkers()
        this.renderMarkers()
        if (this.selectedMarker?.id === id) {
          this.selectedMarker = null
        }
      }
    },

    clearAllMarkers() {
      if (confirm('Supprimer tous les marqueurs ? Cette action est irréversible.')) {
        this.markers = []
        this.saveMarkers()
        this.renderMarkers()
        this.selectedMarker = null
      }
    },

    saveMarkers() {
      try {
        localStorage.setItem('mapeliaMarkers', JSON.stringify(this.markers))
      } catch (e) {
        console.error('Erreur sauvegarde:', e)
      }
    },

    loadMarkers() {
      try {
        const saved = localStorage.getItem('mapeliaMarkers')
        if (saved) {
          this.markers = JSON.parse(saved)
        }
      } catch (e) {
        console.error('Erreur chargement:', e)
      }
    },

    exportMarkers() {
      const data = JSON.stringify(this.markers, null, 2)
      const blob = new Blob([data], { type: 'application/json' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `mapelia-markers-${Date.now()}.json`
      a.click()
      URL.revokeObjectURL(url)
    },

    importMarkers(e) {
      const file = e.target.files?.[0]
      if (!file) return
      const reader = new FileReader()
      reader.onload = () => {
        try {
          const data = JSON.parse(String(reader.result || ''))
          if (Array.isArray(data)) {
            this.markers = data
            this.saveMarkers()
            this.renderMarkers()
          }
        } catch (err) {
          alert('Fichier JSON invalide')
          console.error(err)
        }
      }
      reader.readAsText(file)
      e.target.value = ''
    },

    truncate(text, length) {
      return text.length > length ? text.substring(0, length) + '...' : text
    },

    unlock() {
      if (this.passwordInput === '1612') {
        this.isLocked = false
        sessionStorage.setItem('mapeliaUnlocked', 'true')
        this.$nextTick(() => {
          const token = import.meta.env.VITE_MAPBOX_TOKEN
          if (token) {
            mapboxgl.accessToken = token
            this.initMap()
          }
          this.loadMarkers()
        })
      } else {
        alert('Mot de passe incorrect')
        this.passwordInput = ''
      }
    }
  }
}
</script>

<style scoped>
.mapelia-page {
  display: flex;
  width: 100%;
  height: 100vh;
  background: #f5f5f5;
}

.mapelia-controls {
  width: 360px;
  height: 100%;
  background: #fff;
  border-right: 2px solid #ddd;
  overflow-y: auto;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  color: #333;
  box-shadow: 2px 0 10px rgba(0,0,0,0.1);
}

.back {
  background: #2171b5;
  color: white;
  border: none;
  padding: 10px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  margin-bottom: 10px;
}

.back:hover {
  background: #1a5a8e;
}

.lock-screen {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 20px;
  padding: 40px 20px;
  text-align: center;
}

.lock-icon {
  font-size: 4rem;
}

.lock-screen p {
  color: #666;
  margin: 0;
}

.lock-screen form {
  display: flex;
  flex-direction: column;
  gap: 10px;
  width: 100%;
  max-width: 250px;
}

.password-input {
  padding: 12px;
  border: 2px solid #ddd;
  border-radius: 6px;
  font-size: 1rem;
  text-align: center;
  background: #f9f9f9;
  color: #333;
}

.password-input:focus {
  outline: none;
  border-color: #2171b5;
}

h1 {
  font-size: 1.8rem;
  font-weight: 700;
  margin: 0 0 10px 0;
  color: #333;
}

hr {
  border: none;
  border-top: 1px solid #e0e0e0;
  margin: 10px 0;
}

.controls {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

h3 {
  font-size: 1rem;
  margin: 0 0 8px 0;
  color: #555;
}

.instruction {
  font-size: 0.85rem;
  color: #666;
  margin: 0 0 10px 0;
}

.marker-config {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

label {
  display: flex;
  flex-direction: column;
  gap: 5px;
  font-size: 0.9rem;
  color: #555;
}

input[type="text"],
input[type="color"],
select,
textarea {
  padding: 8px;
  border: 2px solid #ddd;
  border-radius: 4px;
  background: #f9f9f9;
  color: #333;
  font-size: 0.9rem;
  font-family: inherit;
}

input[type="text"]:focus,
select:focus,
textarea:focus {
  outline: none;
  border-color: #2171b5;
  background: #fff;
}

input[type="color"] {
  height: 40px;
  cursor: pointer;
}

textarea {
  resize: vertical;
}

.marker-list {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0;
}

.scroll-container {
  flex: 1;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.marker-item {
  background: #f9f9f9;
  padding: 10px;
  border-radius: 6px;
  border: 2px solid #e0e0e0;
  cursor: pointer;
  transition: all 0.2s;
}

.marker-item:hover {
  border-color: #2171b5;
  background: #fff;
}

.marker-item.active {
  background: #e3f2fd;
  border-color: #2171b5;
}

.marker-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.marker-symbol {
  font-size: 1.2rem;
}

.marker-comment {
  display: block;
  color: #666;
  font-size: 0.85rem;
  margin-top: 4px;
}

.marker-actions {
  display: flex;
  gap: 8px;
  margin-top: 8px;
}

.btn-icon {
  background: transparent;
  border: none;
  font-size: 1rem;
  cursor: pointer;
  padding: 4px;
  opacity: 0.7;
  transition: opacity 0.2s;
}

.btn-icon:hover {
  opacity: 1;
}

.data-tools {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.btn {
  background: #2171b5;
  color: white;
  border: none;
  padding: 10px 12px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
  transition: background 0.2s;
}

.btn:hover {
  background: #1a5a8e;
}

.btn-secondary {
  background: #757575;
}

.btn-secondary:hover {
  background: #616161;
}

.btn-danger {
  background: #d32f2f;
}

.btn-danger:hover {
  background: #b71c1c;
}

.file-label {
  position: relative;
  display: inline-block;
  text-align: center;
}

.file-label input[type="file"] {
  position: absolute;
  opacity: 0;
  width: 0;
  height: 0;
}

.map-container {
  flex: 1;
  position: relative;
  border: 3px solid #333;
}

.map-placeholder {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f5f5f5;
  border: 3px solid #333;
}

.placeholder-content {
  text-align: center;
  color: #999;
}

.lock-icon-large {
  font-size: 6rem;
  margin-bottom: 20px;
}

.placeholder-content p {
  font-size: 1.1rem;
  color: #666;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: #fff;
  border: 2px solid #ddd;
  border-radius: 8px;
  padding: 20px;
  max-width: 500px;
  width: 90%;
  max-height: 80vh;
  overflow-y: auto;
  color: #333;
  box-shadow: 0 4px 20px rgba(0,0,0,0.2);
}

.modal h2 {
  margin: 0 0 15px 0;
  color: #333;
}

.modal label {
  margin-bottom: 10px;
}

.modal-actions {
  display: flex;
  gap: 10px;
  margin-top: 15px;
}

.modal-actions .btn {
  flex: 1;
}

/* Style pour les marqueurs personnalisés */
:deep(.custom-marker) {
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Scrollbar personnalisée */
.scroll-container::-webkit-scrollbar {
  width: 8px;
}

.scroll-container::-webkit-scrollbar-track {
  background: #f5f5f5;
}

.scroll-container::-webkit-scrollbar-thumb {
  background: #ccc;
  border-radius: 4px;
}

.scroll-container::-webkit-scrollbar-thumb:hover {
  background: #aaa;
}
</style>
