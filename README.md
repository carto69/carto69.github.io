# carto69 — Portfolio cartographique

Projet Vue 3 + Vite regroupant différentes cartes interactives (Leaflet/Mapbox) et dashboards.

## Installation

```bash
npm install
```

## Lancer en dev

```bash
npm run dev
```

## Cartes disponibles

- **Cops Kill** — Carte des décès causés par la police française (1977-2024), points géolocalisés avec détails par victime, vues DOM-TOM
- **Femmes de Quais** — Analyse spatiale et temporelle
- **Plouf** — Carte satellite avec masques dynamiques (Paris, Lyon, trajets, buffers)
- **Velib / Velov** — Visualisations de stations de vélos en libre-service
- **Portfolio** — Galerie de cartes et projets avec vignettes et PDFs

## Structure

- `src/components/` — composants Vue des différentes cartes
- `public/` — données CSV/GeoJSON/JSON, fichiers statiques
- `api/` — endpoints serverless Vercel (GBFS, trajets, etc.)

## Déploiement

Le projet est configuré pour Vercel avec routes API serverless.

```bash
vercel --prod
```
