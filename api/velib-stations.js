import fetch from 'node-fetch'

export default async function handler(req, res) {
  try {
    const limit = 500
    let offset = 0
    let hasMore = true
    const stations = {}

    while (hasMore) {
      const url = `https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/velib-disponibilite-en-temps-reel/records?limit=${limit}&offset=${offset}`
      const r = await fetch(url)
      if (!r.ok) {
        return res.status(r.status).json({ error: `opendata returned ${r.status}` })
      }
      const data = await r.json()
      const results = data?.results || []

      results.forEach(station => {
        if (station?.stationcode && station?.coordonnees_geo?.lon != null && station?.coordonnees_geo?.lat != null) {
          stations[station.stationcode] = {
            name: station.name,
            coords: [station.coordonnees_geo.lon, station.coordonnees_geo.lat]
          }
        }
      })

      hasMore = results.length === limit
      offset += limit
    }

    res.setHeader('Access-Control-Allow-Origin', '*')
    res.setHeader('Content-Type', 'application/json')
    res.status(200).json({ stations })
  } catch (e) {
    console.error('velib-stations proxy error:', e)
    res.status(500).json({ error: e.message })
  }
}
