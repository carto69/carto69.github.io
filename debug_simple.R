library(rvest)
library(tidyverse)

url <- "https://oip.org/sinformer/etablissements/"
page <- read_html(url)

cat("=== DEBUG SIMPLE ===\n\n")

# Tous les liens
tous_liens <- page %>% html_elements("a")
cat("Nombre total de liens:", length(tous_liens), "\n\n")

# Liens contenant etablissements
liens_etab <- page %>% html_elements("a[href*='etablissements']")
cat("Liens avec 'etablissements':", length(liens_etab), "\n\n")

cat("10 premiers liens:\n")
for (i in 1:min(10, length(tous_liens))) {
  texte <- html_text2(tous_liens[i]) %>% str_trim() %>% str_sub(1, 40)
  href <- html_attr(tous_liens[i], "href") %>% str_sub(1, 50)
  cat(i, ": ", texte, " => ", href, "\n", sep="")
}

cat("\n\nTexte complet (500 premiers caracteres):\n")
texte <- page %>% html_text2() %>% str_sub(1, 500)
cat(texte, "\n")
