import requests
import json
import time
from pathlib import Path

# Récupérer toutes les villes uniques du CSV
csv_path = 'public/actions-police-fatales.csv'
cities = set()

with open(csv_path, 'r', encoding='utf-8') as f:
    f.readline()  # skip header
    for line in f:
        parts = line.split(',')
        if len(parts) > 9:
            city = parts[9].strip().strip('"')
            if city:
                cities.add(city)

cities = sorted(list(cities))
print(f"Total cities: {len(cities)}")

# Géocoder avec Nominatim (OpenStreetMap)
coordinates = {}
for i, city in enumerate(cities):
    print(f"[{i+1}/{len(cities)}] Geocoding {city}...")
    try:
        # Ajouter ", France" pour améliorer les résultats
        url = f"https://nominatim.openstreetmap.org/search?q={city}, France&format=json&limit=1"
        response = requests.get(url, headers={'User-Agent': 'carto69-copskill'})
        response.raise_for_status()
        
        data = response.json()
        if data:
            result = data[0]
            coordinates[city] = [float(result['lat']), float(result['lon'])]
            print(f"  ✓ Found: {result['display_name']}")
        else:
            print(f"  ✗ Not found")
            
        # Petit délai pour ne pas surcharger Nominatim
        time.sleep(0.1)
    except Exception as e:
        print(f"  ✗ Error: {e}")

# Sauvegarder en JSON
output_path = 'public/city-coordinates.json'
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(coordinates, f, ensure_ascii=False, indent=2)

print(f"\nSaved {len(coordinates)} cities to {output_path}")
print(f"Missing: {len(cities) - len(coordinates)} cities")
