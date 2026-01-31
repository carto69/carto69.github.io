#!/usr/bin/env python3
"""
Script pour extraire les taux d'occupation des places mineurs depuis les PDFs
et les intégrer dans le classeur ODS
"""

import os
import re
import unicodedata
from pathlib import Path
import pdfplumber
from openpyxl import load_workbook
from odf import opendocument
from odf.table import Table, TableRow, TableCell
from odf.text import P

# Chemins
PDF_BASE_DIR = "/home/gesukri/Documents/jdd/condtions_carcéralee_statistiques_mensuelles/avec données à scrap"
ODS_FILE = "/home/gesukri/Documents/jdd/jeunes_prisons/taux_occup_etab_mineur_paranetmois.ods"

# Mapping des mois français vers numéros de colonnes (à ajuster selon le classeur)
MOIS_MAPPING = {
    'janvier': 1,
    'fevrier': 2,
    'mars': 3,
    'avril': 4,
    'mai': 5,
    'juin': 6,
    'juillet': 7,
    'aout': 8,
    'septembre': 9,
    'octobre': 10,
    'novembre': 11,
    'decembre': 12
}

def extraire_tableau29_depuis_pdf(pdf_path):
    """
    Extrait le tableau 29 (Répartition des mineurs détenus par établissement)
    et retourne un dictionnaire {établissement: taux_occupation}
    """
    data = {}
    
    try:
        with pdfplumber.open(pdf_path) as pdf:
            for page in pdf.pages:
                text = page.extract_text()
                
                # Chercher le Tableau 29 avec la bonne description
                if "Tableau 29" in text and "Répartition des mineurs détenus par établissement" in text:
                    # Extraire les tableaux de la page
                    tables = page.extract_tables()
                    
                    for table in tables:
                        if not table or len(table) < 2:
                            continue
                        
                        # Trouver la ligne d'en-tête avec "Taux d'occupation"
                        header_row_idx = None
                        taux_col_idx = None
                        etabl_col_idx = 0  # Par défaut première colonne
                        
                        for i, row in enumerate(table):
                            if row and any("Taux d'occupation" in str(cell) if cell else False for cell in row):
                                header_row_idx = i
                                # Trouver l'index de la colonne du taux
                                for j, cell in enumerate(row):
                                    if cell and "Taux d'occupation" in str(cell):
                                        taux_col_idx = j
                                        break
                                break
                        
                        if header_row_idx is not None and taux_col_idx is not None:
                            # Extraire les données ligne par ligne
                            for row in table[header_row_idx + 1:]:
                                if not row or len(row) <= taux_col_idx:
                                    continue
                                
                                etablissements_cell = row[etabl_col_idx]
                                taux_cell = row[taux_col_idx]
                                
                                if not etablissements_cell or not taux_cell:
                                    continue
                                
                                # Les cellules peuvent contenir plusieurs lignes séparées par \n
                                etablissements = str(etablissements_cell).strip().split('\n')
                                taux_values = str(taux_cell).strip().split('\n')
                                
                                # Associer chaque établissement à son taux
                                for etab, taux in zip(etablissements, taux_values):
                                    etab = etab.strip()
                                    taux = taux.strip()
                                    
                                    # Ignorer les lignes "Ensemble de la DI" et les en-têtes
                                    if (etab and taux and 
                                        not etab.startswith("Ensemble") and
                                        not etab.startswith("Etablissement") and
                                        etab != ""):
                                        data[etab] = taux
                    
                    # Si on a trouvé le tableau, on peut arrêter
                    if data:
                        break
    
    except Exception as e:
        print(f"Erreur lors de l'extraction de {pdf_path}: {e}")
        import traceback
        traceback.print_exc()
    
    return data

def extraire_mois_annee_depuis_nom_fichier(filename):
    """
    Extrait le mois et l'année depuis le nom du fichier
    Ex: mensuelle_janvier_2016.pdf -> ('janvier', 2016)
    """
    # Pattern: mensuelle_<mois>_<année>.pdf
    pattern = r'mensuelle_(\w+)_(\d{4})'
    match = re.search(pattern, filename)
    
    if match:
        mois = match.group(1).lower()
        # Normaliser 'aout' -> 'aout' (déjà bon)
        annee = int(match.group(2))
        return mois, annee
    
    return None, None

def charger_ods(filepath):
    """Charge un fichier ODS"""
    return opendocument.load(filepath)

def get_table_by_name(doc, sheet_name):
    """Récupère une feuille (table) par son nom"""
    for table in doc.spreadsheet.getElementsByType(Table):
        if table.getAttribute('name') == sheet_name:
            return table
    return None

def get_cell_value(cell):
    """Récupère la valeur d'une cellule ODS"""
    paragraphs = cell.getElementsByType(P)
    if paragraphs:
        return str(paragraphs[0])
    return ""

def set_cell_value(cell, value):
    """Définit la valeur d'une cellule ODS"""
    # Supprimer les paragraphes existants
    for p in cell.getElementsByType(P):
        cell.removeChild(p)
    # Ajouter le nouveau texte
    p = P()
    p.addText(str(value))
    cell.appendChild(p)

def normaliser_nom_etablissement(nom):
    """Normalise le nom d'un établissement pour la comparaison"""
    # Enlever les accents
    nom = unicodedata.normalize('NFD', nom)
    nom = ''.join(char for char in nom if unicodedata.category(char) != 'Mn')
    
    # Convertir en minuscules
    nom = nom.lower()
    
    # Remplacer les tirets et underscores par des espaces
    nom = nom.replace('-', ' ').replace('_', ' ')
    
    # Enlever les espaces multiples
    nom = re.sub(r'\s+', ' ', nom.strip())
    
    # Enlever les caractères spéciaux (garder seulement lettres et chiffres et espaces)
    nom = re.sub(r'[^\w\s]', '', nom)
    
    return nom

def trouver_taux_pour_etablissement(etablissement_ods, donnees_pdf):
    """
    Trouve le taux d'occupation pour un établissement donné
    en cherchant dans les données extraites du PDF
    """
    etab_norm = normaliser_nom_etablissement(etablissement_ods)
    
    for etab_pdf, taux in donnees_pdf.items():
        etab_pdf_norm = normaliser_nom_etablissement(etab_pdf)
        
        # Comparaison exacte
        if etab_norm == etab_pdf_norm:
            return taux
        
        # Comparaison partielle (l'un contient l'autre)
        if etab_norm in etab_pdf_norm or etab_pdf_norm in etab_norm:
            return taux
    
    return None

def developper_cellules_repetees(row):
    """
    Développe les cellules répétées dans une ligne ODS
    (gère l'attribut number-columns-repeated)
    Retourne une liste "virtuelle" des cellules avec index mappés correctement
    """
    from odf.table import TableCell
    from copy import deepcopy
    
    cells = row.getElementsByType(TableCell)
    cellules_developpees = []
    
    for cell in cells:
        repeat_attr = cell.getAttribute('numbercolumnsrepeated')
        if repeat_attr:
            repeat = int(repeat_attr)
            # Ajouter la cellule pour chaque répétition
            for i in range(repeat):
                if i == 0:
                    cellules_developpees.append(cell)
                else:
                    # Créer une copie de la cellule
                    new_cell = deepcopy(cell)
                    cellules_developpees.append(new_cell)
                    row.addElement(new_cell)
            # Supprimer l'attribut de répétition
            cell.removeAttribute('numbercolumnsrepeated')
        else:
            cellules_developpees.append(cell)
    
    return cellules_developpees

def mettre_a_jour_ods(ods_file, donnees_par_annee):
    """
    Met à jour le fichier ODS avec les données extraites
    donnees_par_annee = {
        2016: {
            'janvier': {'CP Bordeaux Gradignan': '96%', ...},
            'fevrier': {...},
            ...
        },
        ...
    }
    """
    doc = charger_ods(ods_file)
    
    stats = {
        'total_cellules_traitees': 0,
        'cellules_remplies': 0,
        'cellules_vides_marquees': 0
    }
    
    for annee, donnees_mois in donnees_par_annee.items():
        # Trouver la feuille correspondante (ex: "2016")
        table = get_table_by_name(doc, str(annee))
        
        if not table:
            print(f"⚠️  Feuille {annee} non trouvée dans le classeur")
            continue
        
        print(f"\n{'='*60}")
        print(f"Traitement de l'année {annee}")
        print(f"{'='*60}")
        
        # Récupérer toutes les lignes
        rows = table.getElementsByType(TableRow)
        
        if len(rows) < 2:
            print(f"⚠️  Pas assez de lignes dans la feuille {annee}")
            continue
        
        # La première ligne contient les en-têtes (avec les mois)
        # La structure est: Col 0 = Direction Interrégionale, Col 1 = Etablissement, Col 2-13 = Mois
        header_row = rows[0]
        header_cells = header_row.getElementsByType(TableCell)
        
        # Mapper les colonnes aux mois
        col_to_month = {}
        for col_idx, cell in enumerate(header_cells):
            cell_value = get_cell_value(cell).lower().strip()
            if cell_value in MOIS_MAPPING:
                col_to_month[col_idx] = cell_value
        
        print(f"Mois détectés dans les colonnes: {col_to_month}")
        
        # Pour chaque ligne de données, la colonne 1 contient le nom de l'établissement
        for row_idx, row in enumerate(rows[1:], start=1):
            # Développer les cellules répétées
            cells = developper_cellules_repetees(row)
            
            if len(cells) < 2:
                continue
            
            # Colonne 1 = établissement (colonne 0 = Direction Interrégionale)
            etablissement = get_cell_value(cells[1]).strip()
            
            if not etablissement:
                continue
            
            # print(f"  Ligne {row_idx+1}: {etablissement}")
            
            # Pour chaque mois disponible dans les données
            for col_idx, mois in col_to_month.items():
                stats['total_cellules_traitees'] += 1
                
                if mois not in donnees_mois:
                    continue
                
                donnees_etablissements = donnees_mois[mois]
                
                # Chercher le taux pour cet établissement
                taux = trouver_taux_pour_etablissement(etablissement, donnees_etablissements)
                
                # Mettre à jour la cellule
                if col_idx < len(cells):
                    current_val = get_cell_value(cells[col_idx]).strip()
                    
                    if taux:
                        set_cell_value(cells[col_idx], taux)
                        stats['cellules_remplies'] += 1
                        # print(f"    ✓ {mois}: {taux}")
                    elif not current_val:  # La cellule est vide et on n'a pas de donnée
                        set_cell_value(cells[col_idx], "-")
                        stats['cellules_vides_marquees'] += 1
                        # print(f"    - {mois}: pas de donnée")
    
    # Sauvegarder le fichier
    doc.save(ods_file)
    print(f"\n{'='*60}")
    print(f"✓ Classeur mis à jour : {ods_file}")
    print(f"{'='*60}")
    print(f"Statistiques :")
    print(f"  - Cellules traitées: {stats['total_cellules_traitees']}")
    print(f"  - Cellules remplies avec données: {stats['cellules_remplies']}")
    print(f"  - Cellules marquées '-' (pas de donnée): {stats['cellules_vides_marquees']}")
    print(f"{'='*60}")

def main():
    print("Extraction des taux d'occupation des places mineurs...")
    print("=" * 70)
    
    # Structure pour stocker toutes les données
    donnees_par_annee = {}
    
    # Parcourir les 3 années
    for annee in [2016, 2017, 2018]:
        annee_dir = Path(PDF_BASE_DIR) / str(annee)
        
        if not annee_dir.exists():
            print(f"Dossier {annee} non trouvé: {annee_dir}")
            continue
        
        print(f"\n--- Année {annee} ---")
        donnees_par_annee[annee] = {}
        
        # Parcourir tous les PDFs de l'année
        for pdf_file in sorted(annee_dir.glob("*.pdf")):
            print(f"\nTraitement de: {pdf_file.name}")
            
            # Extraire mois et année
            mois, annee_fichier = extraire_mois_annee_depuis_nom_fichier(pdf_file.name)
            
            if not mois or annee_fichier != annee:
                print(f"  Impossible d'extraire le mois/année de {pdf_file.name}")
                continue
            
            print(f"  Mois: {mois}, Année: {annee_fichier}")
            
            # Extraire les données du tableau 29
            data = extraire_tableau29_depuis_pdf(str(pdf_file))
            
            if data:
                print(f"  {len(data)} établissements trouvés")
                donnees_par_annee[annee][mois] = data
            else:
                print(f"  Aucune donnée extraite")
    
    # Mettre à jour le classeur ODS
    print("\n" + "=" * 70)
    print("Mise à jour du classeur ODS...")
    mettre_a_jour_ods(ODS_FILE, donnees_par_annee)
    
    print("\n✓ Terminé !")

if __name__ == "__main__":
    main()
