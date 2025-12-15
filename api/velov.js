import express from 'express'
import fetch from 'node-fetch'

const router = express.Router()

router.get('/trips', async (req, res) => {
  try {
    const ACCOUNT_ID = '17b0ba03-3184-4c02-89f1-51e8bb7a7d43'
    const CONTRACT = 'lyon'
    
    // Récupérer les trajets
    const response = await fetch(
      `https://api.cyclocity.fr/contracts/${CONTRACT}/accounts/${ACCOUNT_ID}/trips`,
      {
        method: 'GET',
        headers: {
          'Accept': 'application/vnd.trip.v5+json',
          'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
        }
      }
    )

    if (!response.ok) {
      return res.status(response.status).json({ 
        error: `API returned ${response.status}` 
      })
    }

    const trips = await response.json()
    
    // Headers CORS
    res.setHeader('Access-Control-Allow-Origin', '*')
    res.setHeader('Content-Type', 'application/json')
    
    res.json(trips)
    
  } catch (error) {
    console.error('Error:', error)
    res.status(500).json({ error: error.message })
  }
})

export default router
