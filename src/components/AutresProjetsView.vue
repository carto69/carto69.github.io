<template>
  <div class="autres-projets-page">
    <aside class="sidebar">
      <button class="back" @click="$emit('back')">← Retour</button>
      <h1>Autres projets</h1>
      
      <div class="description">
        <p>Découvrez d'autres projets cartographiques et analyses spatiales.</p>
      </div>
    </aside>

    <div class="content-area">
      <div class="projects-grid">
        <article class="project-card">
          <div class="project-icon">🚧</div>
          <h2>Projet à venir</h2>
          <p>Espace réservé pour de futurs projets cartographiques.</p>
        </article>

        <article class="project-card">
          <div class="project-icon">🚧</div>
          <h2>Projet à venir</h2>
          <p>Espace réservé pour de futurs projets cartographiques.</p>
        </article>

        <article class="project-card">
          <div class="project-icon">🚧</div>
          <h2>Projet à venir</h2>
          <p>Espace réservé pour de futurs projets cartographiques.</p>
        </article>

        <article class="project-card">
          <div class="project-icon">🚧</div>
          <h2>Projet à venir</h2>
          <p>Espace réservé pour de futurs projets cartographiques.</p>
        </article>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AutresProjetsView'
}
</script>

<style scoped>
.autres-projets-page {
  display: flex;
  width: 100%;
  height: 100vh;
  background: #f5f5f5;
}

.sidebar {
  width: 300px;
  height: 100%;
  background: #fff;
  border-right: 2px solid #ddd;
  overflow-y: auto;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 15px;
  box-shadow: 2px 0 10px rgba(0,0,0,0.1);
}

.back {
  background: #1a1a1a;
  color: white;
  border: none;
  padding: 10px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  margin-bottom: 10px;
  transition: background 0.2s;
}

.back:hover {
  background: #000;
}

h1 {
  font-size: 1.8rem;
  font-weight: 700;
  margin: 0;
  color: #333;
  line-height: 1.3;
}

.description {
  color: #666;
  font-size: 0.95rem;
  line-height: 1.6;
}

.content-area {
  flex: 1;
  padding: 40px;
  overflow-y: auto;
}

.projects-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 24px;
  max-width: 1400px;
  margin: 0 auto;
}

.project-card {
  background: white;
  border-radius: 12px;
  padding: 30px 24px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  transition: transform 0.2s, box-shadow 0.2s;
  text-align: center;
  cursor: pointer;
  border: 2px solid #e0e0e0;
}

.project-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 16px rgba(0,0,0,0.15);
  border-color: #ccc;
}

.project-icon {
  font-size: 3rem;
  margin-bottom: 16px;
}

.project-card h2 {
  font-size: 1.3rem;
  font-weight: 600;
  color: #333;
  margin: 0 0 12px 0;
}

.project-card p {
  font-size: 0.95rem;
  color: #666;
  line-height: 1.5;
  margin: 0;
}

/* Responsive */
@media (max-width: 768px) {
  .autres-projets-page {
    flex-direction: column;
  }

  .sidebar {
    width: 100%;
    height: auto;
    max-height: 30vh;
  }

  .content-area {
    padding: 20px;
  }

  .projects-grid {
    grid-template-columns: 1fr;
  }
}

/* Scrollbar */
.sidebar::-webkit-scrollbar,
.content-area::-webkit-scrollbar {
  width: 8px;
}

.sidebar::-webkit-scrollbar-track,
.content-area::-webkit-scrollbar-track {
  background: #f5f5f5;
}

.sidebar::-webkit-scrollbar-thumb,
.content-area::-webkit-scrollbar-thumb {
  background: #ccc;
  border-radius: 4px;
}

.sidebar::-webkit-scrollbar-thumb:hover,
.content-area::-webkit-scrollbar-thumb:hover {
  background: #aaa;
}
</style>
