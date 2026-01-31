# Script pour scraper les établissements OIP avec RSelenium
# Car le site charge les données en JavaScript

library(RSelenium)
library(rvest)
library(tidyverse)

cat("=== Scraping OIP avec Selenium ===\n\n")

# Démarrer le serveur Selenium avec Chrome
cat("Démarrage du navigateur...\n")
driver <- rsDriver(
  browser = "firefox",  # ou "chrome" si vous préférez
  chromever = NULL,
  port = 4444L,
  verbose = FALSE
)

remDr <- driver[["client"]]

# Aller sur la page
url <- "https://oip.org/sinformer/etablissements/"
cat("Chargement de:", url, "\n")
remDr$navigate(url)

# Attendre que la page charge (ajuster le temps si nécessaire)
cat("Attente du chargement JavaScript...\n")
Sys.sleep(5)

# Récupérer le HTML après exécution du JavaScript
page_source <- remDr$getPageSource()[[1]]
page <- read_html(page_source)

cat("HTML récupéré, analyse...\n\n")

# Maintenant extraire les établissements
liens_etablissements <- page %>%
  html_elements("a[href*='/sinformer/etablissements/']") %>%
  keep(function(a) {
    href <- html_attr(a, "href")
    texte <- html_text2(a) %>% str_trim()
    
    !is.na(href) && 
      str_detect(href, "/sinformer/etablissements/[a-z0-9-]+$") &&
      nchar(texte) > 10 &&
      str_detect(texte, "^(Centre|Maison|Etablissement|UHSA|UHSI|Quartier)")
  })

cat("Établissements trouvés:", length(liens_etablissements), "\n\n")

# Fonction pour parser les infos
parse_etablissement_texte <- function(texte_bloc) {
  lignes <- str_split(texte_bloc, "\n")[[1]] %>% 
    str_trim() %>% 
    .[. != ""]
  
  nom <- NA
  adresse <- NA
  disp <- NA
  date <- NA
  nature <- NA
  
  for (i in seq_along(lignes)) {
    ligne <- lignes[i]
    
    if (is.na(nom) && str_detect(ligne, "^(Centre|Maison|Etablissement|UHSA|UHSI|Quartier)")) {
      nom <- ligne
    } else if (str_detect(ligne, "^Adresse")) {
      adresse <- str_remove(ligne, "^Adresse\\s*")
      if (i < length(lignes) && !str_detect(lignes[i+1], "^(Disp|Date|Nature|Centre|Maison)")) {
        adresse <- paste(adresse, lignes[i+1])
      }
    } else if (str_detect(ligne, "^Disp")) {
      disp <- str_remove(ligne, "^Disp\\s*")
    } else if (str_detect(ligne, "^Date de mise en service")) {
      date <- str_extract(ligne, "\\d{4}")
    } else if (str_detect(ligne, "^Nature")) {
      nature <- str_remove(ligne, "^Nature\\s*")
    }
  }
  
  list(nom = nom, adresse = adresse, disp = disp, date_mise_en_service = date, nature = nature)
}

# Extraire les données
tous_etablissements <- map_dfr(liens_etablissements, function(lien) {
  nom <- html_text2(lien) %>% str_trim()
  url_etab <- html_attr(lien, "href")
  
  if (!str_detect(url_etab, "^http")) {
    url_etab <- paste0("https://oip.org", url_etab)
  }
  
  parent <- lien
  texte_parent <- ""
  niveau_trouve <- 0
  
  for (i in 1:10) {
    parent <- tryCatch({
      html_element(parent, xpath = "parent::*")
    }, error = function(e) NA)
    
    if (is.na(parent)) break
    
    texte_parent <- html_text2(parent)
    
    if (str_detect(texte_parent, "Adresse") && 
        str_detect(texte_parent, "Disp") && 
        str_detect(texte_parent, "Nature")) {
      niveau_trouve <- i
      break
    }
  }
  
  if (niveau_trouve > 0) {
    info <- parse_etablissement_texte(texte_parent)
    if (is.na(info$nom)) info$nom <- nom
    
    tibble(
      nom = info$nom,
      adresse = info$adresse,
      disp = info$disp,
      date_mise_en_service = info$date_mise_en_service,
      nature = info$nature,
      url = url_etab
    )
  } else {
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

# Fermer le navigateur
cat("\nFermeture du navigateur...\n")
remDr$close()
driver[["server"]]$stop()

# Nettoyer et sauvegarder
if (nrow(tous_etablissements) > 0) {
  tous_etablissements <- tous_etablissements %>%
    filter(!is.na(nom), nom != "") %>%
    distinct() %>%
    arrange(nom)
  
  cat("\n=== Résultats ===\n")
  cat("Établissements extraits:", nrow(tous_etablissements), "\n")
  print(head(tous_etablissements, 10))
  
  write_csv(tous_etablissements, "etablissements_oip.csv")
  saveRDS(tous_etablissements, "etablissements_oip.rds")
  cat("\n✓ Données sauvegardées\n")
  
  cat("\nRépartition par nature:\n")
  print(table(tous_etablissements$nature, useNA = "ifany"))
} else {
  cat("\n✗ Aucune donnée extraite\n")
}
