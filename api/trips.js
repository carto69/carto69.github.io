const { getAccessToken, authenticateUser, getTrips } = require('./velov-client');

module.exports = async (req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const { email, password } = req.body;

    if (!email || !password) {
      res.status(400).json({ error: 'Email and password required' });
      return;
    }

    // Récupérer le token d'accès client
    const clientAccessToken = await getAccessToken();

    // Authentifier l'utilisateur
    const userTokens = await authenticateUser(email, password, clientAccessToken);

    // Récupérer les trajets
    const contract = process.env.VITE_VELOV_CONTRACT || 'lyon';
    const trips = await getTrips(contract, email, userTokens.accessToken, userTokens.idToken);

    // Formater les trajets pour le frontend
    const formattedTrips = (trips || []).map(trip => ({
      id: trip.id,
      startTime: trip.startTime,
      endTime: trip.endTime,
      duration: trip.duration,
      bikeType: trip.bikeType,
      startStation: {
        id: trip.startStation?.id,
        name: trip.startStation?.name,
        lat: trip.startStation?.position?.lat,
        lng: trip.startStation?.position?.lng
      },
      endStation: {
        id: trip.endStation?.id,
        name: trip.endStation?.name,
        lat: trip.endStation?.position?.lat,
        lng: trip.endStation?.position?.lng
      }
    }));

    res.status(200).json({ trips: formattedTrips });
  } catch (error) {
    console.error('API Error:', error);
    res.status(500).json({ error: error.message || 'Internal server error' });
  }
};
