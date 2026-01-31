import csv
import json
import re

# Lire le CSV avec le dialecte correct
data = []
with open('/home/gesukri/Documents/carto69/public/cracarte/cra.csv', 'r', encoding='utf-8') as f:
    # Lire ligne par ligne et parser manuellement
    lines = f.readlines()
    
    for line in lines[1:]:  # Skip header
        # Split par la première occurrence de "CRA" et "LRA"
        if not line.strip():
            continue
            
        parts = re.split(r'(CRA|LRA)', line.strip())
        if len(parts) < 2:
            continue
        
        entry_type = parts[1]  # CRA ou LRA
        content = parts[2] if len(parts) > 2 else ""
        
        # Extraire les champs principaux
        fields = []
        in_quotes = False
        current = ""
        for char in content:
            if char == '"':
                in_quotes = not in_quotes
            elif char == ',' and not in_quotes:
                fields.append(current.strip())
                current = ""
            else:
                current += char
        fields.append(current.strip())
        
        if len(fields) < 6:
            continue
        
        # Extraire les coordonnées (x=lat, y=lon dans le CSV original)
        try:
            lat = float(fields[6].strip()) if len(fields) > 6 else None
            lon = float(fields[7].strip()) if len(fields) > 7 else None
        except:
            lat = None
            lon = None
        
        if not lat or not lon:
            continue
        
        entry = {
            'type': entry_type,
            'nom': fields[1].strip() if len(fields) > 1 else '',
            'lieu': fields[4].strip() if len(fields) > 4 else '',
            'adresse': fields[5].strip() if len(fields) > 5 else '',
            'lat': lat,
            'lon': lon
        }
        
        if entry['lat'] and entry['lon']:
            data.append(entry)

# Écrire le JSON
with open('/home/gesukri/Documents/carto69/public/cracarte/cra.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"Conversion réussie : {len(data)} entrées")

