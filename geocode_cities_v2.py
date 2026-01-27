#!/usr/bin/env python3
import csv
import requests
import json
import time
from pathlib import Path

# Liste des départements français (qu'on doit éviter)
DEPARTMENTS = {
    'Ain', 'Aisne', 'Allier', 'Alpes-Maritimes', 'Alpes-de-Haute-Provence', 'Ardèche', 'Ardennes',
    'Ariège', 'Aube', 'Aude', 'Aveyron', 'Bas-Rhin', 'Bouches-du-Rhône', 'Calvados', 'Cantal',
    'Charente', 'Charente-Maritime', 'Cher', 'Chesapeake', 'Chevreuse', 'Chevreuse',
    'Corse-du-Sud', 'Côte-d\'Or', 'Côte d\'Armor', 'Côtes-d\'Armor', 'Creuse', 'Dordogne', 'Doubs',
    'Drôme', 'Essonne', 'Eure', 'Eure-et-Loir', 'Finistère', 'Gard', 'Gers', 'Gironde',
    'Guadeloupe', 'Guyane', 'Haut-Rhin', 'Haute-Corse', 'Haute-Garonne', 'Haute-Loire', 'Haute-Savoie',
    'Haute-Vienne', 'Hautes-Alpes', 'Hautes-Pyrénées', 'Hauts-de-Seine', 'Hérault', 'Ille-et-Vilaine',
    'Indre', 'Indre-et-Loire', 'Isère', 'Jura', 'La Réunion', 'Landes', 'Loir-et-Cher', 'Loire',
    'Loire-Atlantique', 'Loiret', 'Lot', 'Lot-et-Garonne', 'Lozère', 'Maine-et-Loire', 'Manche',
    'Marne', 'Martinique', 'Mayenne', 'Mayotte', 'Meurthe-et-Moselle', 'Meuse', 'Morbihan',
    'Moselle', 'Nièvre', 'Nord', 'Oise', 'Orne', 'Paris', 'Pas-de-Calais', 'Puy-de-Dôme',
    'Pyrénées-Atlantiques', 'Pyrénées-Orientales', 'Rhône', 'Saône-et-Loire', 'Sarthe', 'Savoie',
    'Seine-et-Marne', 'Seine-Maritime', 'Seine-et-Oise', 'Somme', 'Tarn', 'Tarn-et-Garonne',
    'Territoire de Belfort', 'Territoire-de-Belfort', 'Val-de-Marne', 'Val-d\'Oise', 'Var', 'Vaucluse',
    'Vendée', 'Vienne', 'Vosges', 'Yonne', 'Yvelines'
}

# Récupérer toutes les villes uniques du CSV
csv_path = 'public/actions-police-fatales.csv'
cities = set()

with open(csv_path, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        city = row.get('ville', '').strip()
        if city and city not in DEPARTMENTS:
            cities.add(city)

cities = sorted(list(cities))
print(f"Total cities (excluding departments): {len(cities)}")

# Charger les coordonnées existantes
coords_path = Path('public/city-coordinates.json')
if coords_path.exists():
    with coords_path.open('r', encoding='utf-8') as f:
        coordinates = json.load(f)
else:
    coordinates = {}

# Géocoder avec Nominatim
for i, city in enumerate(cities):
    if city in coordinates:
        print(f"[{i+1}/{len(cities)}] {city} (already cached)")
        continue
    
    print(f"[{i+1}/{len(cities)}] Geocoding {city}...", end=' ')
    try:
        url = f"https://nominatim.openstreetmap.org/search?q={city}, France&format=json&limit=1"
        response = requests.get(url, headers={'User-Agent': 'carto69-copskill'})
        response.raise_for_status()
        
        data = response.json()
        if data:
            result = data[0]
            coordinates[city] = [float(result['lat']), float(result['lon'])]
            print(f"✓ {result['display_name'][:60]}")
        else:
            print("✗ Not found")
            
        time.sleep(0.1)
    except Exception as e:
        print(f"✗ Error: {e}")

# Sauvegarder en JSON
coords_path.parent.mkdir(parents=True, exist_ok=True)
with coords_path.open('w', encoding='utf-8') as f:
    json.dump(coordinates, f, ensure_ascii=False, indent=2)

print(f"\nSaved {len(coordinates)} cities to {coords_path}")
print(f"Missing: {len(cities) - len(coordinates)} cities")
