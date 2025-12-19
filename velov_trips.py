import requests
import json

# Mets ici tes cookies de session (copie depuis l’onglet Application > Cookies)
cookies = {
    'AUTH_SESSION_ID' : 'NjNkNzJjYTAtZTYzMy00NDU0LWE2NTctOTY1MzdkMGE1Zjg4LmF2ZGs1WFM0eVJEQVV3VGcwT3NJS2VCTTVLaC1OaTlkVG5HMzBqZDNhWTVPdUtVZFYtRGlCWTlPV3QwS3Z3VHdvVS1uYzU0RkVOazNlc0ZmR05UcEh3',
    'INGRESSCOOKIE' : '1766076811.318.2740.322069|2edcc0a8cf6ef1d97bc39c18a663d129'
    # Ajoute d'autres cookies si besoin (AUTH_SESSION_ID, etc.)
}

headers = {
    "Accept": "application/json"
}

url = 'https://api.cyclocity.fr/contracts/lyon/accounts/17b0ba03-3184-4c02-89f1-51e8bb7a7d43/trips'

response = requests.get(url, cookies=cookies, headers=headers)


response = requests.get(url, cookies=cookies)
print("Status code:", response.status_code)
if response.status_code != 200:
    print("Erreur d'accès à l'API. Vérifie tes cookies et l'URL.")
    print(response.text)
    exit()

try:
    data = response.json()
except Exception as e:
    print("Erreur de parsing JSON :", e)
    print(response.text)
    exit()

# Extraction des départs/arrivées
for trip in data.get('trips', []):
    print("Départ:", trip.get('startStation'), "| Arrivée:", trip.get('endStation'))

# Pour sauvegarder tous les trajets en JSON :
with open("velov_trips_export.json", "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Export JSON complet dans velov_trips_export.json")