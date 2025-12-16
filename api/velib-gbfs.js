const fetch = require('node-fetch')

module.exports = async function handler(req, res) {
  try {
    const gbfsUrl = 'https://velib-metropole-opendata.smoove.pro/gbfs/2/fr/station_information.json'
    const r = await fetch(gbfsUrl)
    if (!r.ok) {
      return res.status(r.status).json({ error: `GBFS returned ${r.status}` })
    }
    const data = await r.json()
    const list = data?.data?.stations || []
    const stations = {}
    list.forEach(s => {
      if (s.station_id && s.lat != null && s.lon != null) {
        stations[String(s.station_id)] = { name: s.name, coords: [s.lon, s.lat] }
      }
    })
    res.setHeader('Access-Control-Allow-Origin', '*')
    res.setHeader('Content-Type', 'application/json')
    res.status(200).json({ stations })
  } catch (e) {
    console.error('velib-gbfs proxy error:', e)
    res.status(500).json({ error: e.message })
  }
}
