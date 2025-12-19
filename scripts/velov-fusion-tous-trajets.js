// Script pour fusionner et cartographier TOUS les trajets (anciens + Jacques) sans doublon
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const eliaTripsPath = path.join(__dirname, '../public/velovs-trips-elia.json');
const jacquesTripsPath = path.join(__dirname, '../public/velovs-trips-jacques.json');
const stationsPath = path.join(__dirname, '../public/metropole-de-lyon_pvo_patrimoine_voirie.pvostationvelov.json');
const outputPath = path.join(__dirname, '../public/velov-trips.json');
const backupPath = path.join(__dirname, '../public/velov-trips.old.json');

function loadJSON(p) {
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function extractStationsFromGeoJSON(geojson) {
  if (!geojson.features) return [];
  return geojson.features.map(f => ({
    id: f.properties.idstation,
    name: f.properties.nom,
    lng: f.geometry.coordinates[0],
    lat: f.geometry.coordinates[1],
    commune: f.properties.commune || '',
    address: f.properties.adresse1 || ''
  }));
}

function findStation(stations, id) {
  return stations.find(s => String(s.id) === String(id));
}

function convertTrip(trip, stations) {
  const start = findStation(stations, trip.startStation);
  const end = findStation(stations, trip.endStation);
  if (!start || !end) return null;
  return {
    id: trip.id,
    startTime: trip.startDateTime,
    endTime: trip.endDateTime,
    duration: trip.duration,
    bikeType: trip.bikeType === 1 ? 'classic' : 'electric',
    startStation: {
      name: start.name,
      lng: start.lng,
      lat: start.lat,
      commune: start.commune,
      address: start.address
    },
    endStation: {
      name: end.name,
      lng: end.lng,
      lat: end.lat,
      commune: end.commune,
      address: end.address
    },
    geometry: {
      type: 'LineString',
      coordinates: [
        [start.lng, start.lat],
        [end.lng, end.lat]
      ]
    }
  };
}

function main() {
  const eliaTripsRaw = loadJSON(eliaTripsPath);
  const jacquesTripsRaw = loadJSON(jacquesTripsPath);
  const stationsGeo = loadJSON(stationsPath);
  const stations = extractStationsFromGeoJSON(stationsGeo);

  // Convertir tous les trajets (anciens + Jacques) au format carte
  let ok = 0, fail = 0;
  const allRaw = [...eliaTripsRaw, ...jacquesTripsRaw];
  const seen = new Set();
  const allTrips = allRaw.map(trip => {
    if (seen.has(trip.id)) return null; // éviter doublons
    seen.add(trip.id);
    const conv = convertTrip(trip, stations);
    if (conv) ok++; else fail++;
    return conv;
  }).filter(Boolean);

  try {
    fs.copyFileSync(outputPath, backupPath);
  } catch (e) {
    if (e.code !== 'ENOENT') throw e;
  }
  fs.writeFileSync(outputPath, JSON.stringify(allTrips, null, 2));
  console.log(`Fusion terminée : ${allTrips.length} trajets cartographiés.`);
  console.log(`Trajets convertis : ${ok}, ignorés : ${fail}`);
}

main();
