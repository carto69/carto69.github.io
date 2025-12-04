#!/usr/bin/env python3
"""
Script pour exporter les données VeloV depuis l'API Cyclocity
Utilise la nouvelle API avec OpenID Connect (Keycloak)
"""
import requests
import json
import sys
from urllib.parse import urlencode

# Identifiants
EMAIL = 'lix9ix3l@gmail.com'
PASSWORD = '691375'
CONTRACT = 'lyon'
ACCOUNT_ID = '17b0ba03-3184-4c02-89f1-51e8bb7a7d43'

# URLs
IAM_BASE_URL = 'https://iam.cyclocity.fr'
API_BASE_URL = 'https://api.cyclocity.fr'
CLIENT_ID = 'vls-web-lyon'

def get_tokens():
    """
    Obtenir les tokens d'authentification via OpenID Connect
    """
    print("🔐 Authentification en cours...")
    
    session = requests.Session()
    
    # Étape 1: Initier la login
    login_url = f'{IAM_BASE_URL}/realms/vls-default/protocol/openid-connect/auth'
    params = {
        'client_id': CLIENT_ID,
        'redirect_uri': 'https://velov.grandlyon.com/',
        'response_type': 'code',
        'scope': 'openid profile email',
        'state': 'test123'
    }
    
    # Étape 2: Se connecter directement
    login_direct_url = f'{IAM_BASE_URL}/realms/vls-default/protocol/openid-connect/token'
    
    login_data = {
        'username': EMAIL,
        'password': PASSWORD,
        'client_id': CLIENT_ID,
        'grant_type': 'password',
        'scope': 'openid profile email'
    }
    
    try:
        response = session.post(login_direct_url, data=login_data)
        response.raise_for_status()
        tokens = response.json()
        
        return {
            'access_token': tokens.get('access_token'),
            'id_token': tokens.get('id_token'),
            'refresh_token': tokens.get('refresh_token')
        }
    except Exception as e:
        print(f"❌ Erreur d'authentification: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"   Réponse: {e.response.text}")
        return None

def get_trips(tokens):
    """
    Récupérer les trajets avec les tokens
    """
    if not tokens or not tokens.get('access_token'):
        print("❌ Tokens invalides")
        return None
    
    print(f"🚴 Récupération des trajets...")
    
    url = f'{API_BASE_URL}/contracts/{CONTRACT}/accounts/{ACCOUNT_ID}/trips'
    
    headers = {
        'Accept': 'application/vnd.trip.v5+json',
        'Authorization': f"Taknv1 {tokens['access_token']}",
        'Identity': tokens['id_token']
    }
    
    try:
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            trips = response.json()
            print(f"✅ {len(trips)} trajets récupérés!")
            return trips
        elif response.status_code == 403:
            print(f"❌ Accès refusé (403)")
            print(f"   Réponse: {response.text}")
            return None
        elif response.status_code == 401:
            print(f"❌ Non autorisé (401) - Token invalide")
            print(f"   Réponse: {response.text}")
            return None
        else:
            print(f"❌ Erreur {response.status_code}")
            print(f"   Réponse: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return None

def main():
    print("=" * 50)
    print("Export VeloV Data")
    print("=" * 50)
    
    # Authentification
    tokens = get_tokens()
    if not tokens:
        sys.exit(1)
    
    # Récupérer les trajets
    trips = get_trips(tokens)
    if trips is None:
        sys.exit(1)
    
    # Sauvegarder
    output_file = 'public/velov-trips.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(trips, f, indent=2, ensure_ascii=False)
    
    print(f"💾 Données sauvegardées dans {output_file}")
    
    if trips:
        print(f"\n📊 Statistiques:")
        print(f"   - Nombre de trajets: {len(trips)}")
        
        # Statistiques simples
        total_duration = sum(t.get('duration', 0) for t in trips if t.get('duration'))
        hours = total_duration // 60
        mins = total_duration % 60
        print(f"   - Durée totale: {hours}h {mins}m")
        
        if trips:
            first_trip = trips[0]
            last_trip = trips[-1]
            print(f"   - Premier trajet: {first_trip.get('startTime', 'N/A')}")
            print(f"   - Dernier trajet: {last_trip.get('startTime', 'N/A')}")

if __name__ == '__main__':
    main()
