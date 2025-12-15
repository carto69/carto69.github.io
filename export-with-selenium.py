#!/usr/bin/env python3
"""
Script pour exporter les données VeloV en utilisant Selenium
Simule un vrai navigateur pour bypasser les problèmes CORS et d'expiration
"""
import json
import time
import sys
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.service import Service

EMAIL = 'lix9ix3l@gmail.com'
PASSWORD = '691375'

def get_trips_with_selenium():
    """
    Utilise Selenium pour se logger et récupérer les trajets
    """
    print("=" * 60)
    print("VeloV Data Export with Selenium")
    print("=" * 60)
    
    # Configuration Chrome
    chrome_options = Options()
    # Décommente la ligne suivante pour mode headless (sans GUI)
    # chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-blink-features=AutomationControlled")
    
    print("\n🌐 Lancement du navigateur...")
    driver = webdriver.Chrome(
        service=Service(ChromeDriverManager().install()),
        options=chrome_options
    )
    
    try:
        # Aller sur la page de login
        print("📍 Accès à la page VeloV...")
        driver.get("https://velov.grandlyon.com/fr/my-account#TRIPS")
        
        # Attendre que la page charge
        time.sleep(3)
        
        # Chercher le bouton de login ou les champs de connexion
        try:
            # Attendre le formulaire
            wait = WebDriverWait(driver, 10)
            
            # Essayer de trouver le champ email
            email_input = wait.until(
                EC.presence_of_element_located((By.CSS_SELECTOR, "input[type='email'], input[name*='email'], input[id*='email']"))
            )
            print("✍️  Saisie de l'email...")
            email_input.clear()
            email_input.send_keys(EMAIL)
            
            # Chercher le champ password
            password_input = driver.find_element(By.CSS_SELECTOR, "input[type='password']")
            print("✍️  Saisie du mot de passe...")
            password_input.clear()
            password_input.send_keys(PASSWORD)
            
            # Cliquer sur le bouton de login
            login_button = driver.find_element(By.CSS_SELECTOR, "button[type='submit'], button:contains('Connexion'), button:contains('Se connecter')")
            print("🔐 Clic sur le bouton de connexion...")
            login_button.click()
            
            # Attendre que la page charge après login
            time.sleep(5)
            
        except Exception as e:
            print(f"⚠️  Formulaire de login non trouvé, peut-être déjà connecté: {e}")
        
        # Maintenant, utiliser les DevTools pour capturer la requête API
        print("📊 Exécution du script de récupération des données...")
        
        result = driver.execute_script("""
            return new Promise((resolve, reject) => {
                fetch("https://api.cyclocity.fr/contracts/lyon/accounts/17b0ba03-3184-4c02-89f1-51e8bb7a7d43/trips", {
                    headers: {
                        "accept": "application/vnd.trip.v5+json"
                    },
                    credentials: "include"
                })
                .then(r => {
                    if (!r.ok) throw new Error('Status ' + r.status);
                    return r.json();
                })
                .then(data => {
                    console.log('Trajets reçus:', data.length);
                    resolve(data);
                })
                .catch(error => {
                    console.error('Erreur fetch:', error);
                    reject(error.message);
                });
            });
        """)
        
        trips = result
        print(f"\n✅ {len(trips)} trajets récupérés!")
        
        # Sauvegarder
        output_file = 'public/velov-trips.json'
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(trips, f, indent=2, ensure_ascii=False)
        
        print(f"💾 Données sauvegardées dans {output_file}")
        
        # Stats
        if trips:
            total_duration = sum(t.get('duration', 0) for t in trips)
            hours = total_duration // 60
            mins = total_duration % 60
            print(f"\n📊 Statistiques:")
            print(f"   - Trajets: {len(trips)}")
            print(f"   - Durée totale: {hours}h {mins}m")
            print(f"\n✅ Succès! Vous pouvez maintenant déployer sur Vercel.")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Erreur: {e}")
        import traceback
        traceback.print_exc()
        return False
        
    finally:
        print("\n🔒 Fermeture du navigateur...")
        driver.quit()

if __name__ == '__main__':
    success = get_trips_with_selenium()
    sys.exit(0 if success else 1)
