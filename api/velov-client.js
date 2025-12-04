const axios = require('axios');

const CYCLOCITY_BASE_URL = 'https://api.cyclocity.fr';
const CLIENT_CODE = process.env.VITE_VELOV_CLIENT_CODE || 'vls.web.lyon:PRD';
const CLIENT_KEY = process.env.VITE_VELOV_CLIENT_KEY;

// Obtenir un token d'accès
async function getAccessToken() {
  try {
    const response = await axios.post(
      `${CYCLOCITY_BASE_URL}/auth/environments/PRD/client_tokens`,
      {
        clientCode: CLIENT_CODE,
        clientKey: CLIENT_KEY
      }
    );
    return response.data.accessToken;
  } catch (error) {
    console.error('Error getting access token:', error.response?.data || error.message);
    throw new Error('Failed to get access token');
  }
}

// Authentifier l'utilisateur
async function authenticateUser(email, password, accessToken) {
  try {
    // Étape 1: Demander le code d'autorisation
    const authResponse = await axios.get(
      `${CYCLOCITY_BASE_URL}/identities/users/login`,
      {
        params: {
          takn: accessToken,
          email,
          password
        }
      }
    );
    
    const authorizationCode = authResponse.data.authorizationCode;

    // Étape 2: Échanger le code pour les tokens
    const tokenResponse = await axios.post(
      `${CYCLOCITY_BASE_URL}/identities/token`,
      {
        code: authorizationCode,
        clientCode: CLIENT_CODE,
        clientKey: CLIENT_KEY
      }
    );

    return {
      accessToken: tokenResponse.data.accessToken,
      idToken: tokenResponse.data.idToken,
      refreshToken: tokenResponse.data.refreshToken
    };
  } catch (error) {
    console.error('Error authenticating user:', error.response?.data || error.message);
    throw new Error('Failed to authenticate user');
  }
}

// Récupérer les trajets
async function getTrips(contract, email, accessToken, idToken) {
  try {
    const response = await axios.get(
      `${CYCLOCITY_BASE_URL}/contracts/${contract}/accounts/${email}/trips`,
      {
        headers: {
          'Authorization': `Taknv1 ${accessToken}`,
          'Identity': idToken
        }
      }
    );
    return response.data;
  } catch (error) {
    console.error('Error getting trips:', error.response?.data || error.message);
    throw new Error('Failed to get trips');
  }
}

module.exports = {
  getAccessToken,
  authenticateUser,
  getTrips
};
