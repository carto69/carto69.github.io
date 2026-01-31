#!/usr/bin/env python3
"""
Génère un rapport détaillé des correspondances manquantes
"""

from pathlib import Path
from odf import opendocument
from odf.table import Table, TableRow, TableCell
from odf.text import P
from extract_taux_occupation_mineurs import extraire_tableau29_depuis_pdf, normaliser_nom_etablissement, trouver_taux_pour_etablissement

ODS_FILE = "/home/gesukri/Documents/jdd/jeunes_prisons/taux_occup_etab_mineur_paranetmois.ods"
PDF_DIR = "/home/gesukri/Documents/jdd/condtions_carcéralee_statistiques_mensuelles/avec données à scrap/2018"

# Charger le classeur
doc = opendocument.load(ODS_FILE)

# Récupérer tous les établissements du classeur pour 2018
etablissements_ods = []
for table in doc.spreadsheet.getElementsByType(Table):
    if table.getAttribute('name') == '2018':
        rows = table.getElementsByType(TableRow)
        for row_idx in range(1, len(rows)):
            row = rows[row_idx]
            cells = row.getElementsByType(TableCell)
            if len(cells) > 1:
                paragraphs = cells[1].getElementsByType(P)
                etab = str(paragraphs[0]) if paragraphs else ''
                if etab.strip() and not etab.startswith('Total'):
                    etablissements_ods.append(etab.strip())
        break

# Extraire tous les établissements uniques de tous les PDFs de 2018
tous_etablissements_pdf = set()
for pdf_file in sorted(Path(PDF_DIR).glob("*.pdf")):
    data = extraire_tableau29_depuis_pdf(str(pdf_file))
    tous_etablissements_pdf.update(data.keys())

print(f"Établissements dans le classeur ODS: {len(etablissements_ods)}")
print(f"Établissements uniques dans les PDFs 2018: {len(tous_etablissements_pdf)}")
print("\n" + "="*80)
print("ÉTABLISSEMENTS ODS SANS CORRESPONDANCE DANS LES PDFs")
print("="*80)

non_trouves = []
for etab_ods in etablissements_ods:
    taux = trouver_taux_pour_etablissement(etab_ods, {etab: "XX%" for etab in tous_etablissements_pdf})
    if not taux:
        non_trouves.append(etab_ods)

print(f"\n{len(non_trouves)} établissements non trouvés:")
for etab in non_trouves:
    print(f"  - {etab}")

# Chercher des correspondances proches
print("\n" + "="*80)
print("SUGGESTIONS DE CORRESPONDANCES PROCHES")
print("="*80)

for etab_ods in non_trouves[:10]:
    etab_norm = normaliser_nom_etablissement(etab_ods)
    print(f"\n{etab_ods} (normalisé: {etab_norm})")
    
    # Chercher des correspondances partielles
    candidats = []
    for etab_pdf in tous_etablissements_pdf:
        etab_pdf_norm = normaliser_nom_etablissement(etab_pdf)
        
        # Calculer une similarité simple
        mots_ods = set(etab_norm.split())
        mots_pdf = set(etab_pdf_norm.split())
        
        if mots_ods & mots_pdf:  # S'il y a des mots en commun
            nb_communs = len(mots_ods & mots_pdf)
            candidats.append((etab_pdf, nb_communs))
    
    candidats.sort(key=lambda x: x[1], reverse=True)
    
    if candidats:
        print("  Candidats possibles:")
        for candidat, score in candidats[:3]:
            print(f"    - {candidat} (score: {score})")
    else:
        print("  Aucun candidat proche")
