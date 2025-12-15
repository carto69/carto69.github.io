#!/usr/bin/env python3
"""
Script pour récupérer et gérer les tokens VeloV via l'API Cyclocity
Gère correctement le flux OpenID Connect avec Keycloak
"""
import requests
import json
import sys
import time
from datetime import datetime, timedelta
from urllib.parse import urlencode

# Configuration
EMAIL = 'lix9ix3l@gmail.com'
PASSWORD = '691375'
CONTRACT = 'lyon'
ACCOUNT_ID = '17b0ba03-3184-4c02-89f1-51e8bb7a7d43'

# URLs API
IAM_BASE_URL = 'https://iam.cyclocity.fr'
API_BASE_URL = 'https://api.cyclocity.fr'

# Client Keycloak - il faut utiliser le bon client ID
CLIENT_ID = 'vls-web-lyon'
CLIENT_SECRET = ''  # Public client, pas de secret nécessaire

# Headers pour les requêtes
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'application/json',
    'Content-Type': 'application/x-www-form-urlencoded'
}

def get_access_token():
    """
    Obtient un token d'accès valide depuis Keycloak
    """
    print("🔐 Récupération du token d'accès...")
    
    token_url = f'{IAM_BASE_URL}/realms/vls-default/protocol/openid-connect/token'
    
    # Payload pour le flux password grant
    payload = {
        'grant_type': 'password',
        'client_id': CLIENT_ID,
        'username': EMAIL,
        'password': PASSWORD,
        'scope': 'openid profile email'
    }
    
    try:
        response = requests.post(
            token_url,
            data=payload,
            headers=HEADERS,
            timeout=10
        )
        
        if response.status_code == 200:
            token_data = response.json()
            access_token = token_data.get('access_token')
            expires_in = token_data.get('expires_in', 0)
            
            print(f"✅ Token reçu avec succès")
            print(f"⏱️  Valide pour {expires_in} secondes (~{expires_in//60} minutes)")
            
            # Afficher les informations du token
            if 'refresh_token' in token_data:
                print(f"🔄 Token de rafraîchissement disponible")
            
            return access_token, expires_in
        else:
            print(f"❌ Erreur {response.status_code}")
            print(f"Réponse: {response.text}")
            return None, None
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erreur de connexion: {e}")
        return None, None


def get_trips(access_token):
    """
    Récupère les trajets de l'utilisateur avec le token
    """
    print(f"\n📍 Récupération des trajets...")
    
    trips_url = f'{API_BASE_URL}/contracts/{CONTRACT}/accounts/{ACCOUNT_ID}/trips'
    
    headers = HEADERS.copy()
    headers['Authorization'] = f'Bearer {access_token}'
    headers['Accept'] = 'application/vnd.trip.v5+json'
    
    params = {
        'offset': 0,
        'length': 1000  # Récupérer jusqu'à 1000 trajets
    }
    
    try:
        response = requests.get(
            trips_url,
            headers=headers,
            params=params,
            timeout=10
        )
        
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            trips = response.json()
            if isinstance(trips, list):
                print(f"✅ {len(trips)} trajets récupérés")
                return trips
            elif isinstance(trips, dict) and 'data' in trips:
                data = trips.get('data', [])
                print(f"✅ {len(data)} trajets récupérés")
                return data
            else:
                print(f"⚠️  Format de réponse inattendu")
                print(json.dumps(trips, indent=2, ensure_ascii=False)[:500])
                return None
        else:
            print(f"❌ Erreur {response.status_code}")
            print(f"Headers: {dict(response.headers)}")
            print(f"Réponse: {response.text[:500]}")
            return None
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erreur de connexion: {e}")
        return None


def format_trips_for_geojson(trips):
    """
    Formate les trajets pour l'utilisation dans l'application
    """
    if not trips:
        return []
    
    formatted = []
    
    for trip in trips:
        try:
            # Extraire les informations principales
            trip_id = trip.get('id', '')
            start_time = trip.get('startTime', '')
            end_time = trip.get('endTime', '')
            duration = trip.get('duration', 0)
            
            # Infos stations
            start_station = trip.get('startStation', {})
            end_station = trip.get('endStation', {})
            
            start_lat = start_station.get('latitude', 0)
            start_lng = start_station.get('longitude', 0)
            start_name = start_station.get('name', 'Départ')
            
            end_lat = end_station.get('latitude', 0)
            end_lng = end_station.get('longitude', 0)
            end_name = end_station.get('name', 'Arrivée')
            
            # Géométrie (LineString pour la route)
            geometry = trip.get('geometry', {})
            
            formatted_trip = {
                'id': trip_id,
                'startTime': start_time,
                'endTime': end_time,
                'duration': duration,
                'startStation': start_name,
                'endStation': end_name,
                'startLat': start_lat,
                'startLng': start_lng,
                'endLat': end_lat,
                'endLng': end_lng,
                'geometry': geometry,
                'bikeType': trip.get('bikeType', 'classic')
            }
            
            formatted.append(formatted_trip)
        except Exception as e:
            print(f"⚠️  Erreur lors du formatage du trajet: {e}")
            continue
    
    return formatted


def save_trips_json(trips, filename='public/velov-trips.json'):
    """
    Sauvegarde les trajets dans un fichier JSON
    """
    print(f"\n💾 Sauvegarde dans {filename}...")
    
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(trips, f, indent=2, ensure_ascii=False)
        
        print(f"✅ {len(trips)} trajets sauvegardés")
        return True
    except Exception as e:
        print(f"❌ Erreur lors de la sauvegarde: {e}")
        return False


def main():
    """
    Fonction principale
    """
    print("=" * 60)
    print("VeloV Token Manager - Récupération des trajets")
    print("=" * 60)
    print(f"Email: {EMAIL}")
    print(f"Contrat: {CONTRACT}")
    print(f"ID Compte: {ACCOUNT_ID}")
    print("=" * 60)
    
    # Étape 1: Obtenir le token
    access_token, expires_in = get_access_token()
    
    if not access_token:
        print("\n❌ Impossible d'obtenir un token. Arrêt.")
        sys.exit(1)
    
    # Afficher le token (premiers/derniers caractères pour la sécurité)
    token_preview = f"{access_token[:20]}...{access_token[-20:]}"
    print(f"Token: {token_preview}")
    
    # Attendre un peu
    print("\n⏳ Attente de 2 secondes avant de récupérer les trajets...")
    time.sleep(2)
    
    # Étape 2: Récupérer les trajets
    trips = get_trips(access_token)
    
    if trips is None:
        print("\n❌ Impossible de récupérer les trajets. Arrêt.")
        sys.exit(1)
    
    # Étape 3: Formater et sauvegarder
    formatted_trips = format_trips_for_geojson(trips)
    
    if formatted_trips:
        success = save_trips_json(formatted_trips)
        if success:
            print("\n" + "=" * 60)
            print("✅ SUCCÈS - Les trajets sont maintenant disponibles")
            print("=" * 60)
        else:
            sys.exit(1)
    else:
        print("\n⚠️  Aucun trajet à sauvegarder")
        print("Réponse brute:", json.dumps(trips, indent=2, ensure_ascii=False)[:1000])


if __name__ == '__main__':
    main()
