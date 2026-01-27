import fs from 'fs'
import path from 'path'
import { parse as parseCSV } from 'csv-parse/sync'

const csvPath = path.join(process.cwd(), 'public', 'conditionscarcéralesparpays.csv')
const csvContent = fs.readFileSync(csvPath, 'utf8')
const records = parseCSV(csvContent, {
  columns: true,
  skip_empty_lines: true
})

// Créer un mapping ISO3 -> données carcérales
const prisonDataMap = {}
records.forEach(record => {
  const iso3 = record.Code_ISO3 ? record.Code_ISO3.trim() : null
  if (iso3) {
    // Convertir N/A en null
    const parseVal = (v) => {
      if (!v || v === 'N/A' || v.trim() === 'N/A') return null
      const num = parseFloat(v)
      return Number.isFinite(num) ? num : null
    }

    prisonDataMap[iso3] = {
      name: record['Pays / Nations'],
      iso2: record.Code_ISO2,
      population_prison: parseVal(record['Population carcérale totale']),
      taux_pour_100k: parseVal(record['Population carcérale pour 100 000 habitants']),
      taux_occupation: parseVal(record['Taux d\'occupation (%)']),
      attente_jugement: parseVal(record['Détenus en attente de jugement (%)']),
      femmes: parseVal(record['Femmes détenues (%)']),
      etrangers: parseVal(record['Prisonniers étrangers (%)']),
      population: parseVal(record.Population_2023)
    }
  }
})

console.log(`✓ ${Object.keys(prisonDataMap).length} territoires avec données carcérales`)

// Lire le GeoJSON
const geoJsonPath = path.join(process.cwd(), 'public', 'world-boundaries.geojson')
const geojson = JSON.parse(fs.readFileSync(geoJsonPath, 'utf8'))

console.log(`✓ ${geojson.features.length} territoires dans le GeoJSON`)

// Mapping pour les pays avec ISO_A3 = -99 ou codes ISO différents
const nameToISO3 = {
  'France': 'FRA',
  'Norway': 'NOR',
  'Kosovo': 'XKX',
  'Somaliland': 'SOM'
}

// Spécial centroid pour USA (MultiPolygon - donner le centroid continental)
const specialCentroids = {
  'USA': [-95.7129, 37.0902]
}

// Mapping inverse: codes GeoJSON vers codes CSV pour les codes différents
const geoISOtoCSVISO = {
  'XKX': 'XXK',  // Kosovo (GeoJSON: XKX, CSV: XXK)
  'PSE': 'PSE'   // Palestine
}

// Merger les données - utiliser ISO_A3 ou NAME si -99
let matched = 0
geojson.features.forEach((feature, idx) => {
  let iso3 = feature.properties.ISO_A3
  let csvISO3 = iso3
  
  // Si ISO_A3 est invalide, essayer le mapping par nom
  if (iso3 === '-99' || !iso3) {
    const name = feature.properties.NAME
    iso3 = nameToISO3[name] || null
    csvISO3 = iso3
  }
  
  // Vérifier si le code GeoJSON est différent du CSV
  if (geoISOtoCSVISO[csvISO3]) {
    csvISO3 = geoISOtoCSVISO[csvISO3]
  }
  
  if (csvISO3 && prisonDataMap[csvISO3]) {
    feature.properties = {
      ...feature.properties,
      ...prisonDataMap[csvISO3],
      has_data: prisonDataMap[csvISO3].population_prison !== null ? true : false
    }
    matched++
  } else {
    feature.properties.has_data = false
  }
  feature.id = idx // Assurer que chaque feature a un ID unique
})

// Supprimer l'Antarctique et Baikonur
geojson.features = geojson.features.filter(f => {
  const name = f.properties.name || f.properties.NAME || ''
  return f.properties.ISO_A3 !== 'ATA' && name !== 'Baikonur'
})

console.log(`✓ ${matched} territoires mergés avec succès`)
console.log(`✓ ${geojson.features.length} territoires dans le GeoJSON final (Antarctique et Baikonur supprimés)`)

// Sauvegarder le GeoJSON enrichi
const outputPath = path.join(process.cwd(), 'public', 'zonzon', 'world-prison-data.geojson')
const outputDir = path.dirname(outputPath)

if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true })
}

fs.writeFileSync(outputPath, JSON.stringify(geojson, null, 2))
console.log(`✓ Fichier sauvegardé: ${outputPath}`)
console.log(`✓ Taille: ${(fs.statSync(outputPath).size / 1024 / 1024).toFixed(2)} MB`)
