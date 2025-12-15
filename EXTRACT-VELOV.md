# Comment extraire tes trajets Velo'v

## Méthode console (1 minute)

1. Ouvre https://velov.grandlyon.com/fr/my-account#TRIPS
2. Ouvre les DevTools (F12) > onglet **Console**
3. Colle ce script complet et appuie sur Entrée:

```javascript
(async function() {
  console.log('🚴 Extraction des trajets Velo\'v...');
  
  try {
    const accountId = '17b0ba03-3184-4c02-89f1-51e8bb7a7d43';
    const contract = 'lyon';
    
    // Récupérer le token depuis localStorage ou sessionStorage
    let token = null;
    try {
      // Chercher le token d'authentification
      const keys = Object.keys(localStorage);
      for (const key of keys) {
        const val = localStorage.getItem(key);
        if (val && (val.includes('eyJ') || val.includes('Bearer'))) {
          token = val.replace('Bearer ', '').trim();
          break;
        }
      }
    } catch {}
    
    if (!token) {
      console.error('❌ Token non trouvé. Assure-toi d\'être connecté.');
      return;
    }
    
    console.log('✅ Token trouvé');
    
    // Récupérer les trajets
    const url = `https://api.cyclocity.fr/contracts/${contract}/accounts/${accountId}/trips`;
    const response = await fetch(url, {
      headers: {
        'accept': 'application/vnd.trip.v5+json',
        'authorization': `Bearer ${token}`,
        'content-type': 'application/vnd.trip.v5+json'
      }
    });
    
    if (!response.ok) {
      console.error(`❌ Erreur ${response.status}: ${response.statusText}`);
      return;
    }
    
    const data = await response.json();
    console.log(`✅ ${data.length} trajets récupérés`);
    
    // Normaliser les données
    function pickStation(st) {
      if (!st) return null;
      const lat = st.position?.latitude ?? st.latitude ?? st.lat;
      const lng = st.position?.longitude ?? st.longitude ?? st.lng ?? st.lon;
      const name = st.name ?? st.label ?? 'Station';
      return { name, lat: lat != null ? +lat : null, lng: lng != null ? +lng : null };
    }
    
    const trips = data.map((t, i) => ({
      id: t.id ?? `trip-${i}`,
      startTime: t.startTime ?? t.startedAt ?? null,
      endTime: t.endTime ?? t.endedAt ?? null,
      duration: t.duration ?? 0,
      bikeType: t.bikeType ?? 'classic',
      startStation: pickStation(t.startStation),
      endStation: pickStation(t.endStation),
      geometry: t.geometry ?? null
    }));
    
    console.log('✅ Données formatées');
    
    // Télécharger le fichier
    const blob = new Blob([JSON.stringify(trips, null, 2)], { type: 'application/json' });
    const downloadUrl = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = downloadUrl;
    a.download = 'velov-trips.json';
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(downloadUrl);
    
    console.log('✅ Fichier téléchargé: velov-trips.json');
    console.log('📁 Envoie ce fichier à Copilot pour l\'intégrer au projet');
    
  } catch (err) {
    console.error('❌ Erreur:', err);
  }
})();
```

4. Le fichier `velov-trips.json` se télécharge automatiquement
5. Dis-moi "fichier prêt" et je l'intègre au projet

## Alternative: Network

Si le script ne marche pas:
1. Dans DevTools > onglet **Network**
2. Filtre: `trips`
3. Recharge la page des trajets
4. Clique sur la requête `trips`
5. Onglet **Response** > clic droit > Copy > Copy response
6. Va sur https://carto69.vercel.app/import-velov.html
7. Colle le JSON > "Analyser et convertir" > "Télécharger"
