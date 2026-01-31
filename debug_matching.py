#!/usr/bin/env python3
"""
Script de debug pour vérifier les correspondances entre les noms
d'établissements dans le classeur ODS et dans les PDFs
"""

from odf import opendocument
from odf.table import Table, TableRow, TableCell
from odf.text import P
from extract_taux_occupation_mineurs import extraire_tableau29_depuis_pdf, normaliser_nom_etablissement

ODS_FILE = "/home/gesukri/Documents/jdd/jeunes_prisons/taux_occup_etab_mineur_paranetmois.ods"
PDF_PATH = "/home/gesukri/Documents/jdd/condtions_carcéralee_statistiques_mensuelles/avec données à scrap/2018/mensuelle_decembre_2018.pdf"

# Charger le classeur
doc = opendocument.load(ODS_FILE)

# Récupérer les établissements du classeur pour 2018
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

# Extraire les établissements du PDF
etablissements_pdf = extraire_tableau29_depuis_pdf(PDF_PATH)

print(f"Établissements dans le classeur ODS (2018): {len(etablissements_ods)}")
print(f"Établissements dans le PDF (déc 2018): {len(etablissements_pdf)}")
print("\n" + "="*80)
print("COMPARAISON DES NOMS")
print("="*80)

# Comparer
matches = 0
no_matches = []

for etab_ods in etablissements_ods[:20]:  # Premiers 20
    etab_norm = normaliser_nom_etablissement(etab_ods)
    found = False
    
    for etab_pdf in etablissements_pdf.keys():
        etab_pdf_norm = normaliser_nom_etablissement(etab_pdf)
        
        if etab_norm == etab_pdf_norm or etab_norm in etab_pdf_norm or etab_pdf_norm in etab_norm:
            print(f"✓ \"{etab_ods}\" -> \"{etab_pdf}\" = {etablissements_pdf[etab_pdf]}")
            matches += 1
            found = True
            break
    
    if not found:
        no_matches.append(etab_ods)
        print(f"✗ \"{etab_ods}\" -> PAS DE CORRESPONDANCE")

print(f"\n{matches} correspondances trouvées sur {len(etablissements_ods[:20])} établissements testés")

if no_matches:
    print(f"\nÉtablissements sans correspondance:")
    for etab in no_matches:
        print(f"  - {etab}")
    
    print(f"\nQuelques établissements du PDF pour comparaison:")
    for i, etab_pdf in enumerate(list(etablissements_pdf.keys())[:10]):
        print(f"  - {etab_pdf}")
