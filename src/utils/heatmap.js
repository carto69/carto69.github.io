// Heatmap utility for VeloV trips
export function createHeatmapData(trips) {
  if (!trips || trips.length === 0) return [];

  const heatmapData = [];

  trips.forEach(trip => {
    // Ajouter la station de départ
    if (trip.startStation?.lat && trip.startStation?.lng) {
      heatmapData.push({
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [trip.startStation.lng, trip.startStation.lat]
        },
        properties: {
          intensity: 1,
          type: 'start'
        }
      });
    }

    // Ajouter la station d'arrivée
    if (trip.endStation?.lat && trip.endStation?.lng) {
      heatmapData.push({
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [trip.endStation.lng, trip.endStation.lat]
        },
        properties: {
          intensity: 1,
          type: 'end'
        }
      });
    }
  });

  return {
    type: 'FeatureCollection',
    features: heatmapData
  };
}

export function createRoutesData(trips) {
  if (!trips || trips.length === 0) return [];

  const routes = trips
    .filter(trip => 
      trip.startStation?.lat && trip.startStation?.lng &&
      trip.endStation?.lat && trip.endStation?.lng
    )
    .map(trip => ({
      type: 'Feature',
      geometry: {
        type: 'LineString',
        coordinates: [
          [trip.startStation.lng, trip.startStation.lat],
          [trip.endStation.lng, trip.endStation.lat]
        ]
      },
      properties: {
        id: trip.id,
        startStation: trip.startStation.name,
        endStation: trip.endStation.name,
        duration: trip.duration,
        bikeType: trip.bikeType,
        startTime: trip.startTime,
        endTime: trip.endTime
      }
    }));

  return {
    type: 'FeatureCollection',
    features: routes
  };
}
