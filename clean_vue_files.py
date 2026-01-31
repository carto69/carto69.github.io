#!/usr/bin/env python3
import re
import os

def clean_vue_file(filepath):
    """Nettoie un fichier Vue en supprimant commentaires et lignes vides excessives"""
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Supprimer les commentaires HTML <!-- -->
    content = re.sub(r'<!--.*?-->', '', content, flags=re.DOTALL)
    
    # Supprimer les commentaires JavaScript //
    lines = content.split('\n')
    cleaned_lines = []
    for line in lines:
        # Supprimer les commentaires // (sauf les URLs)
        if '//' in line and not '://' in line:
            # Garder le contenu avant le commentaire
            before_comment = line.split('//')[0].rstrip()
            if before_comment:
                cleaned_lines.append(before_comment)
        else:
            cleaned_lines.append(line)
    
    content = '\n'.join(cleaned_lines)
    
    # Supprimer les commentaires CSS /* */
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
    
    # Réduire les lignes vides excessives (plus de 1 ligne vide consécutive)
    content = re.sub(r'\n\n\n+', '\n\n', content)
    
    # Nettoyer les indentations excessives
    lines = content.split('\n')
    cleaned = []
    for i, line in enumerate(lines):
        # Supprimer les espaces trailing
        line = line.rstrip()
        # Garder les lignes vides une fois
        if line or (i + 1 < len(lines) and lines[i + 1].strip()):
            cleaned.append(line)
    
    content = '\n'.join(cleaned).strip() + '\n'
    
    return content

# Liste des fichiers à nettoyer
files_to_clean = [
    '/home/gesukri/Documents/carto69/src/components/VelovView.vue',
    '/home/gesukri/Documents/carto69/src/components/MapeliaView.vue',
    '/home/gesukri/Documents/carto69/src/components/ZonzonView.vue',
    '/home/gesukri/Documents/carto69/src/components/Velo13View.vue',
    '/home/gesukri/Documents/carto69/src/components/DashboardRView.vue',
    '/home/gesukri/Documents/carto69/src/components/FemmesQuaisView.vue',
    '/home/gesukri/Documents/carto69/src/components/PloufMap.vue',
    '/home/gesukri/Documents/carto69/src/components/XploreMap.vue',
    '/home/gesukri/Documents/carto69/src/components/CopsKillView.vue',
    '/home/gesukri/Documents/carto69/src/components/SontlaMap.vue',
    '/home/gesukri/Documents/carto69/src/components/VelibView.vue',
    '/home/gesukri/Documents/carto69/src/components/MapView.vue',
    '/home/gesukri/Documents/carto69/src/components/CracarteView.vue',
    '/home/gesukri/Documents/carto69/src/components/MenuView.vue',
    '/home/gesukri/Documents/carto69/src/components/PortfolioView.vue',
    '/home/gesukri/Documents/carto69/src/App.vue'
]

for filepath in files_to_clean:
    if os.path.exists(filepath):
        print(f"Nettoyage: {filepath}")
        cleaned = clean_vue_file(filepath)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(cleaned)
        print(f"✓ Nettoyé: {filepath}")
    else:
        print(f"✗ Fichier non trouvé: {filepath}")

print("\n✅ Nettoyage terminé!")
