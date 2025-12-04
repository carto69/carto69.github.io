#!/usr/bin/env python3
"""
Script pour télécharger tes données VeloV depuis le navigateur via clipboard
"""
import pyperclip
import json
import os

print("=" * 60)
print("VeloV Data Downloader")
print("=" * 60)
print()
print("Instructions:")
print("1. Va sur https://velov.grandlyon.com/fr/my-account#TRIPS")
print("2. Ouvre la DevTools (F12)")
print("3. Va dans l'onglet Console")
print("4. Copie-colle ce code et appuie sur Entrée:")
print()
print("""
fetch("https://api.cyclocity.fr/contracts/lyon/accounts/17b0ba03-3184-4c02-89f1-51e8bb7a7d43/trips", {
  headers: {
    "accept": "application/vnd.trip.v5+json",
    "authorization": "Taknv1 eyJhbGciOiJSUzI1NiIsInppcCI6IkRFRiJ9.eJzVmNuymjAUht8l15apnU67y3UfoLNvO70IYanRHGkOKuP47k2iILbETbYM2itCjh__muxwgFpW6AcbZnOdlBkrJYi__H6Hc0QtqUbsErkBm_Eh1JyTEVOasLkeQbsK5TPv375_PIy__bx0wxtQbklczdUKY7yAyKSZ2tSAsF2n4WlhJo6I1iV2o8bECj_iQioZe1WlbZgVLiGkZZJq8E1t5QJarVvYQaC-D6BBanDlVvlrs0jCrrxw8yK0l24ZavzJkbWmGPXKEC7tdI_g1HGQBslubvRsPW3p70N6LDLHnghrVr6m7X7aWsswh7Kjfi1HhKnIMLsOmzKsaKFVOjXDCnJgjavNVeAS99JKtd5OB5nUTRSGIWJScfTQOlimgpPF0kXVYun4XIG1cHT6B2OaIF_99G5kOjgaZGNTOcC5IrTFZQW1Zt0oubxUoeDKSWxHMRt7_RiGjm0InTe6Z0onVZvvlPUhL-77QnQuh0lMHBzhnD0WtMZ_uuwv9g1SO-Kv36HvZmeovEXtA63mF7Jqg9Nb0a6EXx3oRk3-KJogtYENAYbKgVsIxHYw2Vy94wdgVeah6OSiwWodBtNk6XGjrCT2LQKIGKhvhfbrQJgugT0fgs1cocDUrCL1I_PYJ-x68ez2uF4MCHSvpWCJiiRxn2BRfk0cnPC3FTj5iQTo6VbSA3tfemnxtwTFU7RlHQR3FAbgqlSkoDWvZRSnfVEmSlKqdWbVdiQVebOv6ytNHsHz0VnZEy7SnQQaAG7hx__JnKilzo8UCusNlQsH27AiVJ_IzcBkKLErRjh_Pd_BGhQm1yip1fnj6w87zjAnOR2jnizpi_BU9EDzaRf68Yt1qMhFznJHI9_AEv4RJY.Yz3LH3TFDrgxQbI9SyEiiqpJ_nubplF3iYASgOnZEtONa_IkVV6WLWS8KPEyl-IH-KAHCxn3j1lfbn8ZbfmAN3j9a_uEQZDlRY_X-d9piDh4RBMUyCBFEfxpSeVZ0qDvNkELFJMFy9oUbl00yKF1a9afg6UCeL8S2OXM1kOkcZUgE1IyoHJ0SFEogLCRZBwrTb-PY7dTNYRjYeiOKLxiU5Wn1u97jrP4l1XqwTZI8qj5FiTfYB9EcZidTobS1rX8Pgg7k0tZduJ2KTNCayAMA2AdS-VqUlOubOPQqtFrNAfK66_ryowVTKQrbpqX5alDudeLaaSWbK5b-48GcbSlmw",
    "identity": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJyZDVpNTR1b1VZdkw1dGtybUlZXzdvYnFDbWtLN2FDM01pMGxxQk1CaGs4In0.eyJleHAiOjE3NjQ4NzU2MDIsImlhdCI6MTc2NDg3NDcwMiwiYXV0aF90aW1lIjoxNzY0Nzk4NDYzLCJqdGkiOiJhYTU3YzRjMy0wMTdjLTQ4OTQtODg2OC00NzVmMmU3NGI1NTciLCJpc3MiOiJodHRwczovL2lhbS5jeWNsb2NpdHkuZnIvcmVhbG1zL3Zscy1kZWZhdWx0IiwiYXVkIjoiYWNjb3VudCIsInN1YiI6ImxpeDlpeDNsQGdtYWlsLmNvbSIsInR5cCI6IkJlYXJlciIsImF6cCI6InZscy13ZWItbHlvbiIsInNpZCI6IjYzZDcyY2EwLWU2MzMtNDQ1NC1hNjU3LTk2NTM3ZDBhNWY4OCIsImFjciI6IjAiLCJhbGxvd2VkLW9yaWdpbnMiOlsiaHR0cHM6Ly93d3cudmVsb3YuZ3JhbmRseW9uLmNvbSIsImh0dHBzOi8vdmVsb3YuZ3JhbmRseW9uLmNvbSIsImh0dHBzOi8vdmVsb3YuY3ljbG9jaXR5LmZyIl0sInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJvZmZsaW5lX2FjY2VzcyIsImNvbnRyYWN0LWx5b24tdXNlciIsInVtYV9hdXRob3JpemF0aW9uIiwiZGVmYXVsdC1yb2xlcy12bHMtZGVmYXVsdCJdfSwicmVzb3VyY2VfYWNjZXNzIjp7ImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJtYW5hZ2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sInNjb3BlIjoib3BlbmlkIHByb2ZpbGUgZW1haWwiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwicHJlZmVycmVkX3VzZXJuYW1lIjoibGl4OWl4M2xAZ21haWwuY29tIiwibG9jYWxlIjoiZnIifQ.VIInIRhdoS3rlJ4X7sphuewoWx7zXpnIYViVzSRI5yW7rsnZ2vNy5LUug2iR-vxetdk-jKyyS_KFHYjFM7ku0r8hVAGyApzIGZBUynDYx_LyU6P-tc_g09BxgnAcHni8sSJ53urnC1JaNweCm_F2ob5pHXWPGzcAHCRAtAgyrUMP9-vlFf7Crh_wyljvfjpeKhAb4OLFdnAqsivd1n6kmLRXWEjHjRdpRGrCMWt88xX-3DqbsSkT7yvcXQvowxz-a1rKgwl_D4bKvLClQ6fdVuXNUDlhWtlmMnl4VSc4GMTJwyAkVoQDF03E3Os58m993UqfeJplhc-x6BmrxF4IKw"
  },
  body: null,
  method: "GET",
  credentials: "include"
}).then(r => r.json()).then(d => {
  console.log('Nombre de trajets:', d.length);
  const text = JSON.stringify(d, null, 2);
  console.log(text);
  // Copie dans le clipboard
  navigator.clipboard.writeText(text).then(() => {
    console.log('✅ Copié dans le clipboard!');
  });
})
""")
print()
print("5. Une fois que ça affiche '✅ Copié dans le clipboard!',")
print("   lance ce script Python et il va sauvegarder le fichier")
print()
input("Appuie sur Entrée quand c'est fait...")

try:
    data_text = pyperclip.paste()
    
    if not data_text or len(data_text) < 10:
        print("❌ Aucune donnée dans le clipboard")
        exit(1)
    
    # Parse le JSON
    trips = json.loads(data_text)
    
    print(f"\n✅ {len(trips)} trajets trouvés!")
    
    # Sauvegarde
    output_file = 'public/velov-trips.json'
    os.makedirs('public', exist_ok=True)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(trips, f, indent=2, ensure_ascii=False)
    
    print(f"💾 Sauvegardé dans {output_file}")
    
    # Stats
    if trips:
        total_duration = sum(t.get('duration', 0) for t in trips)
        hours = total_duration // 60
        mins = total_duration % 60
        print(f"\n📊 Stats:")
        print(f"   - Trajets: {len(trips)}")
        print(f"   - Durée totale: {hours}h {mins}m")
    
except json.JSONDecodeError:
    print("❌ Les données ne sont pas du JSON valide")
    print("Vérifiez que vous avez bien copié la sortie du fetch")
except Exception as e:
    print(f"❌ Erreur: {e}")
