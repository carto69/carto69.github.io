<template>
  <div class="login-page">
    <div class="map-container">
      <img 
        src="/login-map.png" 
        alt="Carte" 
        class="login-map"
        @load="onImageLoad"
        ref="mapImage"
      />
      <div 
        v-if="imageLoaded"
        class="yellow-dot-zone" 
        :style="dotZoneStyle"
        @click="showLoginForm = true"
        title="Cliquer pour se connecter"
      ></div>
    </div>

    <transition name="fade">
      <div v-if="showLoginForm" class="login-overlay" @click="closeIfOutside">
        <div class="login-box" @click.stop>
          <button class="close-btn" @click="showLoginForm = false">×</button>
          <h2>Connexion</h2>
          <form @submit.prevent="handleLogin">
            <div class="form-group">
              <label for="username">Identifiant</label>
              <input 
                type="text" 
                id="username" 
                v-model="username" 
                required
                autocomplete="username"
              />
            </div>
            <div class="form-group">
              <label for="password">Mot de passe</label>
              <input 
                type="password" 
                id="password" 
                v-model="password" 
                required
                autocomplete="current-password"
              />
            </div>
            <p v-if="errorMessage" class="error">{{ errorMessage }}</p>
            <button type="submit" class="submit-btn">Se connecter</button>
          </form>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
export default {
  name: 'LoginView',
  emits: ['authenticated'],
  data() {
    return {
      showLoginForm: false,
      username: '',
      password: '',
      errorMessage: '',
      imageLoaded: false,
      credentials: []
    }
  },
  computed: {
    dotZoneStyle() {
      // Position du point jaune en bas à droite
      return {}
    }
  },
  async mounted() {
    await this.loadCredentials()
  },
  methods: {
    onImageLoad() {
      this.imageLoaded = true
    },
    async loadCredentials() {
      try {
        const response = await fetch('/credentials.json')
        this.credentials = await response.json()
      } catch (error) {
        console.error('Erreur chargement credentials:', error)
        this.credentials = []
      }
    },
    handleLogin() {
      const user = this.credentials.find(
        u => u.username === this.username && u.password === this.password
      )
      
      if (user) {
        localStorage.setItem('carto69_authenticated', 'true')
        localStorage.setItem('carto69_user', this.username)
        this.$emit('authenticated')
      } else {
        this.errorMessage = 'Identifiant ou mot de passe incorrect'
        setTimeout(() => {
          this.errorMessage = ''
        }, 3000)
      }
    },
    closeIfOutside(e) {
      if (e.target.classList.contains('login-overlay')) {
        this.showLoginForm = false
      }
    }
  }
}
</script>

<style scoped>
.login-page {
  width: 100vw;
  height: 100vh;
  background: #ffffff;
  display: flex;
  justify-content: center;
  align-items: center;
  overflow: hidden;
}

.map-container {
  position: relative;
  max-width: 90vw;
  max-height: 90vh;
}

.login-map {
  display: block;
  max-width: 100%;
  max-height: 90vh;
  height: auto;
  width: auto;
}

.yellow-dot-zone {
  position: absolute;
  width: 80px;
  height: 80px;
  border-radius: 50%;
  cursor: pointer;
  transition: all 0.3s ease;
  bottom: 6%;
  right: 18%;
  z-index: 10;
}

.yellow-dot-zone:hover {
  transform: scale(1.3);
  background: rgba(255, 193, 7, 0.3);
  box-shadow: 0 0 20px rgba(255, 193, 7, 0.5);
}

.login-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.login-box {
  background: white;
  padding: 40px;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
  min-width: 320px;
  position: relative;
}

.close-btn {
  position: absolute;
  top: 10px;
  right: 10px;
  background: none;
  border: none;
  font-size: 32px;
  color: #999;
  cursor: pointer;
  line-height: 1;
  padding: 0;
  width: 32px;
  height: 32px;
  transition: color 0.2s;
}

.close-btn:hover {
  color: #333;
}

.login-box h2 {
  margin: 0 0 24px 0;
  color: #333;
  font-size: 24px;
  text-align: center;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  color: #555;
  font-weight: 500;
}

.form-group input {
  width: 100%;
  padding: 12px;
  border: 2px solid #ddd;
  border-radius: 6px;
  font-size: 16px;
  transition: border-color 0.2s;
  box-sizing: border-box;
}

.form-group input:focus {
  outline: none;
  border-color: #4a9f6d;
}

.error {
  color: #e63b3b;
  margin: 16px 0;
  font-size: 14px;
  text-align: center;
}

.submit-btn {
  width: 100%;
  padding: 12px;
  background: #2d7d4d;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.submit-btn:hover {
  background: #4a9f6d;
}

.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s;
}

.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>
