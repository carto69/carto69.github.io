# Script pour scraper les établissements pénitentiaires depuis OIP
# URL: https://oip.org/sinformer/etablissements/
# Note: La pagination est en JavaScript, on scrappe donc uniquement la page visible

library(rvest)
library(tidyverse)
library(httr)

# Fonction pour extraire les infos depuis le texte structuré d'un établissement
parse_etablissement_texte <- function(texte_bloc) {
  lignes <- str_split(texte_bloc, "\n")[[1]] %>% 
    str_trim() %>% 
    .[. != ""]
  
  # Initialiser les variables
  nom <- NA
  adresse <- NA
  disp <- NA
  date <- NA
  nature <- NA
  
  # Parcourir les lignes
  for (i in seq_along(lignes)) {
    ligne <- lignes[i]
    
    # Le nom est généralement la première ligne qui commence par Centre/Maison/etc
    if (is.na(nom) && str_detect(ligne, "^(Centre|Maison|Etablissement|UHSA|UHSI|Quartier)")) {
      nom <- ligne
    }
    # Adresse (peut être sur plusieurs lignes)
    else if (str_detect(ligne, "^Adresse")) {
      adresse <- str_remove(ligne, "^Adresse\\s*")
      # Capturer aussi la ligne suivante si elle ne commence pas par un mot-clé
      if (i < length(lignes) && !str_detect(lignes[i+1], "^(Disp|Date|Nature|Centre|Maison)")) {
        adresse <- paste(adresse, lignes[i+1])
      }
    }
    # DISP
    else if (str_detect(ligne, "^Disp")) {
      disp <- str_remove(ligne, "^Disp\\s*")
    }
    # Date
    else if (str_detect(ligne, "^Date de mise en service")) {
      date <- str_extract(ligne, "\\d{4}")
    }
    # Nature
    else if (str_detect(ligne, "^Nature")) {
      nature <- str_remove(ligne, "^Nature\\s*")
    }
  }
  
  list(nom = nom, adresse = adresse, disp = disp, date_mise_en_service = date, nature = nature)
}

# Fonction principale de scraping
scrape_etablissements <- function(url) {
  cat("Scraping:", url, "\n")
  
  page <- tryCatch({
    read_html(url)
  }, error = function(e) {
    cat("Erreur lors du chargement de la page:", e$message, "\n")
    return(NULL)
  })
  
  if (is.null(page)) return(tibble())
  
  # Stratégie : trouver tous les liens vers les établissements
  liens_etablissements <- page %>%
    html_elements("a[href*='/sinformer/etablissements/']") %>%
    keep(function(a) {
      href <- html_attr(a, "href")
      texte <- html_text2(a) %>% str_trim()
      
      # Filtrer pour ne garder que les vrais liens d'établissements
      !is.na(href) && 
        str_detect(href, "/sinformer/etablissements/[a-z0-9-]+$") &&
        nchar(texte) > 10 &&
        str_detect(texte, "^(Centre|Maison|Etablissement|UHSA|UHSI|Quartier)")
    })
  
  cat("→ Liens d'établissements trouvés:", length(liens_etablissements), "\n")
  
  if (length(liens_etablissements) == 0) {
    cat("Aucun lien trouvé. Affichage des 10 premiers liens de la page:\n")
    tous_liens <- page %>% html_elements("a") %>% head(10)
    for (lien in tous_liens) {
      cat("  -", html_text2(lien), "=>", html_attr(lien, "href"), "\n")
    }
    return(tibble())
  }
  
  # Pour chaque lien, extraire les infos du bloc parent
  etablissements <- map_dfr(liens_etablissements, function(lien) {
    nom <- html_text2(lien) %>% str_trim()
    url_etab <- html_attr(lien, "href")
    
    # Compléter l'URL si relative
    if (!str_detect(url_etab, "^http")) {
      url_etab <- paste0("https://oip.org", url_etab)
    }
    
    # Remonter dans le DOM pour trouver le conteneur avec les métadonnées
    parent <- lien
    texte_parent <- ""
    niveau_trouve <- 0
    
    for (i in 1:10) {
      parent <- tryCatch({
        html_element(parent, xpath = "parent::*")
      }, error = function(e) NA)
      
      if (is.na(parent)) break
      
      texte_parent <- html_text2(parent)
      
      # Chercher le niveau qui contient toutes les métadonnées
      has_adresse <- str_detect(texte_parent, "Adresse")
      has_disp <- str_detect(texte_parent, "Disp")
      has_nature <- str_detect(texte_parent, "Nature")
      
      if (has_adresse && has_disp && has_nature) {
        niveau_trouve <- i
        break
      }
    }
    
    # Parser les métadonnées
    if (niveau_trouve > 0 && str_detect(texte_parent, "Nature")) {
      info <- parse_etablissement_texte(texte_parent)
      
      # Utiliser le nom du lien si le nom parsé est NA
      if (is.na(info$nom)) {
        info$nom <- nom
      }
      
      tibble(
        nom = info$nom,
        adresse = info$adresse,
        disp = info$disp,
        date_mise_en_service = info$date_mise_en_service,
        nature = info$nature,
        url = url_etab
      )
    } else {
      # Si on n'arrive pas à parser, au moins sauver le nom et l'URL
      tibble(
        nom = nom,
        adresse = NA_character_,
        disp = NA_character_,
        date_mise_en_service = NA_character_,
        nature = NA_character_,
        url = url_etab
      )
    }
  })
  
  return(etablissements)
}

# URL de base
base_url <- "https://oip.org/sinformer/etablissements/"

cat("=== Scraping des établissements pénitentiaires OIP ===\n")
cat("Note: La pagination est gérée en JavaScript, seule la première page est accessible\n\n")

# Scraper la page
tous_etablissements <- scrape_etablissements(base_url)

cat("\n=== Nettoyage des données ===\n")
if (nrow(tous_etablissements) > 0 && "nom" %in% names(tous_etablissements)) {
  tous_etablissements <- tous_etablissements %>%
    filter(!is.na(nom), nom != "") %>%
    distinct() %>%
    arrange(nom)
} else {
  tous_etablissements <- tibble(
    nom = character(),
    adresse = character(),
    disp = character(),
    date_mise_en_service = character(),
    nature = character(),
    url = character()
  )
}

# Afficher un résumé
cat("\n=== Résultats du scraping ===\n")
cat("Nombre total d'établissements:", nrow(tous_etablissements), "\n")
cat("Colonnes:", paste(names(tous_etablissements), collapse = ", "), "\n")

if (nrow(tous_etablissements) > 0) {
  cat("\nAperçu des premières lignes:\n")
  print(head(tous_etablissements, 10))
  
  # Sauvegarder les données
  write_csv(tous_etablissements, "etablissements_oip.csv")
  cat("\n✓ Données sauvegardées dans: etablissements_oip.csv\n")
  
  # Créer aussi un fichier RDS pour R
  saveRDS(tous_etablissements, "etablissements_oip.rds")
  cat("✓ Données sauvegardées dans: etablissements_oip.rds\n")
  
  # Statistiques
  cat("\n=== Statistiques ===\n")
  cat("Répartition par nature d'établissement:\n")
  print(table(tous_etablissements$nature, useNA = "ifany"))
  
} else {
  cat("\n✗ ERREUR: Aucune donnée n'a été extraite.\n")
  cat("Le site a peut-être changé de structure ou utilise du JavaScript pour charger les données.\n")
}
