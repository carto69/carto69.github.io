library(shiny)
library(shinydashboard)
library(leaflet)
library(geojsonsf)
library(sf)
library(dplyr)
library(readr)
library(RColorBrewer)
library(ggplot2)
library(stringr)
library(jsonlite)
library(shinyjs)

velhop_data <- fromJSON("stations.json")
stations <- velhop_data$data$stations

stations_sf <- stations %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
  select(station_id, name, short_name, capacity)

enquete_data <- read.csv("tableau_complet_enquete_comove.csv", sep = ";")

enquete_data <- enquete_data %>%
  mutate(
    Genre = case_when(
      tolower(Genre) %in% c("femme", "f") ~ "Femme",
      tolower(Genre) %in% c("homme", "h") ~ "Homme",
      Genre %in% c("ne sait pas", "null", "", NA) ~ "Non spécifié",
      TRUE ~ as.character(Genre)
    ),
    
    Age = case_when(
      Age %in% c("moins de 20", "<20") ~ "Moins de 20 ans",
      Age %in% c("20-40") ~ "20-40 ans",
      Age %in% c("40-60") ~ "40-60 ans",
      Age %in% c("60 et plus", "60+") ~ "60 ans et plus",
      Age %in% c("ne sait pas", "null", "", NA) ~ "Non spécifié",
      TRUE ~ as.character(Age)
    ),
    
    Classe_age = case_when(
      Age %in% c("Moins de 20 ans", "<20") ~ "0-20 ans",
      Age == "20-40 ans" ~ "20-40 ans",
      Age == "40-60 ans" ~ "40-60 ans",
      Age %in% c("60 ans et plus", "60+") ~ "60+ ans",
      TRUE ~ "Non spécifié"
    ),
    
    Mode_transport = case_when(
      tolower(Mode) %in% c("pietons", "piéton", "pieton") ~ "Piéton",
      tolower(Mode) %in% c("cycliste", "cyclistes") ~ "Cycliste",
      Mode %in% c("null", "", NA) ~ "Non spécifié",
      TRUE ~ as.character(Mode)
    )
  )

occupation_data <- read_csv("strasbourg_occ_pct.csv")
actifs_data <- occupation_data %>%
  group_by(district) %>%
  summarise(part_actifs = mean(actives, na.rm = TRUE)) %>%
  ungroup()

districts_sf <- st_read("strasbourg_secteurs.geojson") %>% st_transform(4326)

population_data <- read_csv("strasbourg_pop_nb.csv")
pop_residente <- population_data %>%
  group_by(district) %>%
  summarise(pop = mean(pop0, na.rm = TRUE)) %>%
  ungroup()

districts_data <- districts_sf %>%
  mutate(CODE_SEC = as.numeric(CODE_SEC)) %>%
  left_join(actifs_data, by = c("CODE_SEC" = "district")) %>%
  left_join(pop_residente, by = c("CODE_SEC" = "district"))

breaks_actifs <- c(
  min(districts_data$part_actifs, na.rm = TRUE),
  quantile(districts_data$part_actifs, probs = 0.2, na.rm = TRUE),
  quantile(districts_data$part_actifs, probs = 0.4, na.rm = TRUE),
  quantile(districts_data$part_actifs, probs = 0.6, na.rm = TRUE),
  quantile(districts_data$part_actifs, probs = 0.8, na.rm = TRUE),
  max(districts_data$part_actifs, na.rm = TRUE)
)

breaks_actifs <- round(breaks_actifs, 1)

labels_choropleth <- c(
  paste0(breaks_actifs[1], "% - ", breaks_actifs[2], "%"),
  paste0(breaks_actifs[2], "% - ", breaks_actifs[3], "%"),
  paste0(breaks_actifs[3], "% - ", breaks_actifs[4], "%"),
  paste0(breaks_actifs[4], "% - ", breaks_actifs[5], "%"),
  paste0(breaks_actifs[5], "% - ", breaks_actifs[6], "%")
)

districts_data <- districts_data %>%
  mutate(actifs_classe = cut(part_actifs, 
                             breaks = breaks_actifs, 
                             include.lowest = TRUE, 
                             labels = labels_choropleth))

radius_divisor <- 18

pop_breaks <- quantile(districts_data$pop, probs = seq(0, 1, 0.25), na.rm = TRUE)
radius_breaks <- sqrt(pop_breaks) / radius_divisor

labels_circles <- c(
  paste0("≤ ", round(pop_breaks[2])),
  paste0(round(pop_breaks[2]), " - ", round(pop_breaks[3])),
  paste0(round(pop_breaks[3]), " - ", round(pop_breaks[4])),
  paste0("> ", round(pop_breaks[4]))
)

flux_voies <- st_read("sirac_flux_trafic.geojson") %>% st_transform(4326)

amg_cycl_sf <- st_read("amg_cycl_bnac.geojson", quiet = TRUE) %>%
  mutate(
    d_service = as.character(d_service),
    d_service = str_trim(d_service),
    annee_service = suppressWarnings(as.numeric(str_extract(d_service, "\\b\\d{4}\\b"))),
    
    ame_g = case_when(
      tolower(ame_g) %in% c("aucun", "autre", "autres", "non spécifié", "null", "") ~ "Autres",
      TRUE ~ ame_g
    )
  ) %>%
  mutate(
    annee_service = ifelse(
      annee_service >= 2015 & annee_service <= 2025,
      annee_service,
      NA
    )
  )

temporelle_ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      .temp-container {
        height: 100% !important;
        overflow-y: auto !important;
        padding: 20px !important;
        background-color: white !important;
      }
      .plot-card {
        background-color: white !important;
        border-radius: 8px !important;
        padding: 20px !important;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1) !important;
        margin-bottom: 20px !important;
        border: 1px solid #e0e0e0 !important;
        height: 500px !important;
      }
      .control-panel {
        background-color: #f8f9fa !important;
        border-radius: 8px !important;
        padding: 20px !important;
        margin-bottom: 20px !important;
        border: 1px solid #dee2e6 !important;
      }
    "))
  ),
  
  div(class = "temp-container",
      titlePanel("Analyse temporelle des déplacements"),
      
      fluidRow(
        column(12,
               div(class = "control-panel",
                   fluidRow(
                     column(4,
                            selectInput("categorie_selector", 
                                        "Choisir la catégorie d'analyse:",
                                        choices = c("Motif de déplacement" = "motif", 
                                                    "Mode de transport" = "transport",
                                                    "Classe d'âge" = "age",
                                                    "Genre" = "genre"),
                                        selected = "motif",
                                        width = "100%")
                     ),
                     column(8,
                            div(class = "total-box",
                                textOutput("total_deplacements"),
                                style = "font-size: 14px; font-weight: bold; color: #2C3E50;"
                            )
                     )
                   )
               )
        )
      ),
      
      fluidRow(
        column(12,
               div(class = "plot-card",
                   plotOutput("temp_plot", height = "450px")
               )
        )
      )
  )
)

statistiques_ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      .stats-container {
        height: 100% !important;
        overflow-y: auto !important;
        padding: 20px !important;
        background-color: white !important;
      }
      #camembert_plot, #bar_age_plot, #bar_genre_plot {
        background-color: white !important;
        border-radius: 8px !important;
        padding: 10px !important;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1) !important;
      }
      .selectize-input {
        border-radius: 6px !important;
        border: 2px solid #ddd !important;
        padding: 10px !important;
        font-size: 14px !important;
      }
      .selectize-input:focus {
        border-color: #3498DB !important;
        box-shadow: 0 0 0 0.2rem rgba(52, 152, 219, 0.25) !important;
      }
    "))
  ),
  
  div(class = "stats-container",
      titlePanel("Statistiques sur les enquêté.es de l'enquête Comove 2025"),
      fluidRow(
        column(6,
               selectInput("select_camembert", 
                           "Choisir la variable:",
                           choices = c("Genre", "Âge", "Mode de transport"),
                           selected = "Genre",
                           width = "100%")
        ),
        column(6)
      ),
      
      fluidRow(
        column(6,
               plotOutput("camembert_plot", height = "500px")
        ),
        
        column(6,
               plotOutput("bar_age_plot", height = "250px"),
               br(),
               plotOutput("bar_genre_plot", height = "250px")
        )
      )
  )
)

ressenti_ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      .ressenti-container {
        height: 100% !important;
        overflow-y: auto !important;
        padding: 20px !important;
        background-color: white !important;
      }
      .plot-card-ressenti {
        background-color: white !important;
        border-radius: 8px !important;
        padding: 20px !important;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1) !important;
        margin-bottom: 30px !important;
        border: 1px solid #e0e0e0 !important;
        min-height: 600px !important;
        height: auto !important;
        overflow: visible !important;
      }
      .graph-row {
        margin-bottom: 30px !important;
      }
      .plot-card-ressenti .plot-container {
        height: 450px !important;
        overflow: visible !important;
      }
    "))
  ),
  
  div(class = "ressenti-container",
      titlePanel("Analyse des ressentis par type d'usager.es"),
      
      fluidRow(
        column(12,
               div(class = "stats-box",
                   uiOutput("ressenti_stats"),
                   style = "font-weight: bold; color: #2C3E50;"
               )
        )
      ),
      
      fluidRow(class = "graph-row",
               column(12,
                      div(class = "plot-card-ressenti",
                          h4("1. Par mode de transport"),
                          fluidRow(
                            column(4,
                                   div(class = "select-input-small",
                                       selectInput("var_mode", 
                                                   "Variable de ressenti à visualiser:",
                                                   choices = c("Sentiment de sécurité" = "Sentiment_securite",
                                                               "Perception risque collision" = "Perception_risque_collision_pietons_cyclistes",
                                                               "Perception des tensions" = "Perception_tensions"),
                                                   selected = "Sentiment_securite",
                                                   width = "100%")
                                   )
                            ),
                            column(8,
                                   p("Comparaison des différents modes de transport (piétons / cyclistes)")
                            )
                          ),
                          div(class = "plot-container",
                              plotOutput("ressenti_mode_plot", height = "450px")
                          )
                      )
               )
      ),
      
      fluidRow(class = "graph-row",
               column(12,
                      div(class = "plot-card-ressenti",
                          h4("2. Par genre"),
                          fluidRow(
                            column(4,
                                   div(class = "select-input-small",
                                       selectInput("var_genre", 
                                                   "Variable de ressenti à visualiser:",
                                                   choices = c("Sentiment de sécurité" = "Sentiment_securite",
                                                               "Perception risque collision" = "Perception_risque_collision_pietons_cyclistes",
                                                               "Perception des tensions" = "Perception_tensions"),
                                                   selected = "Perception_risque_collision_pietons_cyclistes",
                                                   width = "100%")
                                   )
                            ),
                            column(8,
                                   p("Comparaison entre hommes et femmes")
                            )
                          ),
                          div(class = "plot-container",
                              plotOutput("ressenti_genre_plot", height = "450px")
                          )
                      )
               )
      ),
      
      fluidRow(class = "graph-row",
               column(12,
                      div(class = "plot-card-ressenti",
                          h4("3. Par fréquence d'utilisation"),
                          fluidRow(
                            column(4,
                                   div(class = "select-input-small",
                                       selectInput("var_freq", 
                                                   "Variable de ressenti à visualiser:",
                                                   choices = c("Sentiment de sécurité" = "Sentiment_securite",
                                                               "Perception risque collision" = "Perception_risque_collision_pietons_cyclistes",
                                                               "Perception des tensions" = "Perception_tensions"),
                                                   selected = "Perception_tensions",
                                                   width = "100%")
                                   )
                            ),
                            column(8,
                                   p("Comparaison selon la fréquence d'utilisation (quotidien, hebdomadaire, etc.)")
                            )
                          ),
                          div(class = "plot-container",
                              plotOutput("ressenti_freq_plot", height = "450px")
                          )
                      )
               )
      ),
      
      fluidRow(class = "graph-row",
               column(12,
                      div(class = "plot-card-ressenti",
                          h4("4. Par classe d'âge"),
                          fluidRow(
                            column(4,
                                   div(class = "select-input-small",
                                       selectInput("var_age", 
                                                   "Variable de ressenti à visualiser:",
                                                   choices = c("Sentiment de sécurité" = "Sentiment_securite",
                                                               "Perception risque collision" = "Perception_risque_collision_pietons_cyclistes",
                                                               "Perception des tensions" = "Perception_tensions"),
                                                   selected = "Sentiment_securite",
                                                   width = "100%")
                                   )
                            ),
                            column(8,
                                   p("Comparaison entre les différentes classes d'âge")
                            )
                          ),
                          div(class = "plot-container",
                              plotOutput("ressenti_age_plot", height = "450px")
                          )
                      )
               )
      )
  )
)

donnees_ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      .donnees-container {
        height: 100% !important;
        overflow-y: auto !important;
        padding: 20px !important;
        background-color: white !important;
        line-height: 1.6;
      }
      .donnees-container h3 {
        color: #2C3E50;
        border-bottom: 2px solid #3498DB;
        padding-bottom: 10px;
        margin-top: 30px;
      }
      .donnees-container h4 {
        color: #3498DB;
        margin-top: 25px;
      }
      .source-box {
        background-color: #f8f9fa;
        border-left: 4px solid #3498DB;
        padding: 15px;
        margin: 15px 0;
        border-radius: 4px;
      }
      .link-text {
        background-color: #e8f4fc;
        padding: 12px;
        margin: 10px 0;
        border-radius: 6px;
        border: 1px solid #d1ecf1;
        font-family: 'Courier New', monospace;
        word-break: break-all;
        font-size: 14px;
        color: #2C3E50;
      }
      .reference-item {
        margin-bottom: 8px;
      }
    "))
  ),
  
  div(class = "donnees-container",
      titlePanel("Données"),
      
      h3("Source des données"),
      
      div(class = "source-box",
          p(tags$b("Enquête Co-Move (COncilier les MObilités actiVEs):"), 
            " Enquête sur la conciliation des mobilités actives."),
          div(class = "link-text",
              "https://anr.fr/Projet-ANR-23-SARP-0012"
          )
      ),
      
      div(class = "source-box",
          p(tags$b("Réseau routier:"), " Données sur les flux de trafic à Strasbourg."),
          div(class = "link-text",
              "https://data.strasbourg.eu/explore/dataset/sirac_flux_trafic/information/"
          )
      ),
      
      div(class = "source-box",
          p(tags$b("Aménagements cyclables:"), " Réseau cyclable de la ville de Strasbourg."),
          div(class = "link-text",
              "https://data.strasbourg.eu/explore/dataset/amg_cycl_bnac/map/?sort=-ame_g&location=16,48.58125,7.75327&basemap=71944e"
          )
      ),
      
      div(class = "source-box",
          p(tags$b("Stations VELHOP:"), " Données des stations de vélos en libre-service."),
          div(class = "link-text",
              "https://data.strasbourg.eu/explore/dataset/velhop_gbfs/information/"
          )
      ),
      
      div(class = "source-box",
          p(tags$b("Secteurs / Quartiers:"), " Découpage administratif de la ville de Strasbourg."),
          div(class = "link-text",
              "https://data.strasbourg.eu/explore/dataset/strasbourg-en-28-quartiers/table/?disjunctive.nom"
          )
      ),
      
      div(class = "source-box",
          p(tags$b("Données démographiques / sociologiques:"), " Données sur la population et les déplacements."),
          div(class = "link-text",
              "https://mobiliscope.cnrs.fr/fr"
          )
      ),
      
      div(class = "source-box",
          p(tags$b("Données OpenStreetMap:"), " Données cartographiques libres."),
          div(class = "link-text",
              "https://www.openstreetmap.org"
          )
      ),
      
      h3("Références techniques"),
      
      p("Ce dashboard a été développé avec les outils suivants:"),
      div(class = "reference-item", tags$b("R"), " - langage de programmation statistique"),
      div(class = "reference-item", tags$b("Shiny"), " - framework pour applications web interactives"),
      div(class = "reference-item", tags$b("shinydashboard"), " - pour l'interface utilisateur"),
      div(class = "reference-item", tags$b("Leaflet"), " - pour la cartographie interactive"),
      div(class = "reference-item", tags$b("ggplot2"), " - pour la création de graphiques"),
      div(class = "reference-item", tags$b("sf"), " - pour le traitement des données spatiales"),
      div(class = "reference-item", tags$b("dplyr"), " - pour la manipulation de données")
  )
)

ui <- dashboardPage(
  
  dashboardHeader(
    title = tags$div(
      style = "text-align: center; width: 100%; height: 65px; background-color: #3498DB; margin: 0; padding: 0;",
      tags$div(style = "position: absolute; left: 50%; transform: translateX(-50%); top: 8px; line-height: 1.1;",
               tags$h4("Analyse des données de l'enquête COMOVE sur les Quais des Bateliers (Strasbourg)", 
                       style = "margin: 0; padding: 0; font-weight: bold; color: white; font-size: 16px;"),
               tags$p("Elia Terragni - M1 Carthagéo - R pour la science des données- Université Paris Cité",
                      style = "margin: 5; padding: 0; font-size: 13px; opacity: 0.8; color: white;")
      ),
      actionButton("toggle_sidebar", 
                   label = NULL,
                   icon = icon("bars"),
                   style = "position: absolute; left: 10px; top: 10px; z-index: 1000;
                          background-color: #2980B9; border: 1px solid #1F618D;
                          color: white; border-radius: 4px; padding: 6px 10px;
                          cursor: pointer;")
    ),
    titleWidth = "100%"
  ),
  
  dashboardSidebar(
    width = 250,
    collapsed = FALSE,
    
    sidebarMenu(
      id = "tabs",
      menuItem(HTML('<div style="display: flex; align-items: center; padding: 10px 0;">
    <span style="font-size: 16px; line-height: 1.3;">Situation de Strasbourg<br/>et des Quais des Bateliers</span>
  </div>'),
               tabName = "carte", 
               selected = TRUE),
      
      menuItem(HTML('<div style="display: flex; align-items: center; padding: 10px 0;">
    <span style="font-size: 16px; line-height: 1.3;">Réseau cyclable <br/>de Strasbourg</span>
  </div>'),
               tabName = "mobilites"),
      
      menuItem(HTML('<div style="display: flex; align-items: center; padding: 10px 0;">
    <span style="font-size: 16px; line-height: 1.3;">Analyse temporelle<br/>des données</span>
  </div>'),
               tabName = "temporelle"),
      
      menuItem(HTML('<div style="display: flex; align-items: center; padding: 10px 0;">
    <span style="font-size: 16px; line-height: 1.3;">Analyse des ressentis<br/></span>
  </div>'),
               tabName = "ressenti"),
      
      menuItem(HTML('<div style="display: flex; align-items: center; padding: 10px 0;">
    <span style="font-size: 16px; line-height: 1.3;">Statistiques sur<br/>les enquêté.es</span>
  </div>'),
               tabName = "stats_comove"),
      
      menuItem(HTML('<div style="display: flex; align-items: center; padding: 10px 0;">
    <span style="font-size: 16px; line-height: 1.3;">Données</span>
  </div>'),
               tabName = "donnees")
    )
  ),
  
  dashboardBody(
    useShinyjs(), 
    
    tags$head(
      tags$style(HTML("
        html, body {
          height: 100% !important;
          margin: 0 !important;
          padding: 0 !important;
          overflow: hidden !important;
        }
        
        .wrapper {
          height: 100vh !important;
          overflow: hidden !important;
        }
        
        .main-header {
          position: fixed !important;
          top: 0 !important;
          width: 100% !important;
          z-index: 2000 !important;
          height: 50px !important;
          margin: 0 !important;
          padding: 0 !important;
          border-bottom: none !important;
        }
        
        .main-sidebar {
          position: fixed !important;
          top: 50px !important;
          height: calc(100vh - 50px) !important;
          overflow-y: auto !important;
          z-index: 1500 !important;
        }
        
        .content-wrapper {
          margin-top: 50px !important;
          margin-left: 250px !important;
          height: calc(100vh - 50px) !important;
          min-height: calc(100vh - 50px) !important;
          padding: 0 !important;
          overflow: hidden !important;
          background-color: white !important;
        }
        
        .content {
          padding: 0 !important;
          margin: 0 !important;
          height: 100% !important;
          min-height: 100% !important;
        }
        
        .tab-content {
          height: 100% !important;
          padding: 0 !important;
          margin: 0 !important;
        }
        
        .tab-pane {
          height: 100% !important;
          padding: 0 !important;
          margin: 0 !important;
          overflow: hidden !important;
        }
        
        .box {
          height: 100% !important;
          padding: 0 !important;
          margin: 0 !important;
          border: none !important;
          background-color: transparent !important;
        }
        
        .leaflet-container {
          height: 100% !important;
          width: 100% !important;
        }
        
        .sidebar-collapsed .main-sidebar {
          display: none !important;
        }
        
        .sidebar-collapsed .content-wrapper {
          margin-left: 0 !important;
        }
        
        .sidebar-toggle {
          display: none !important;
        }
        
        #toggle_sidebar {
          transition: all 0.3s ease;
        }
        
        #toggle_sidebar:hover {
          background-color: #1F618D !important;
          transform: scale(1.05);
        }
        
        .circle-legend-container {
          background: white;
          padding: 8px 10px;
          border-radius: 5px;
          border: 1px solid #ccc;
          box-shadow: 0 2px 6px rgba(0,0,0,0.15);
          font-size: 11px;
          max-width: 180px;
        }
        
        .circle-legend-title {
          font-weight: bold;
          font-size: 12px;
          margin-bottom: 6px;
          border-bottom: 1px solid #ddd;
          padding-bottom: 3px;
          color: #333;
        }
        
        .circle-legend-item {
          display: flex;
          align-items: center;
          margin-bottom: 4px;
        }
        
        .circle-sample {
          border-radius: 50%;
          background-color: blue;
          border: 1px solid darkblue;
          margin-right: 8px;
          flex-shrink: 0;
        }
        
        .custom-title-wrapper {
          position: absolute !important;
          top: 70px !important;
          right: 20px !important;
          z-index: 1000 !important;
          pointer-events: auto !important;
          max-width: 35% !important;
          width: auto !important;
          min-width: 300px !important;
        }
        
        .leaflet-control-custom-title {
          background: white;
          padding: 8px 10px;
          border-radius: 6px;
          border: 2px solid #ccc;
          box-shadow: 0 3px 10px rgba(0,0,0,0.2);
          font-size: 12px;
          line-height: 1.3;
        }
        
        .leaflet-control-custom-title h4 {
          margin: 0 0 5px 0 !important;
          color: #333;
          font-size: 15px !important;
          font-weight: bold;
          line-height: 1.2 !important;
        }
        
        .leaflet-control-custom-title .sources {
          border-top: 1px solid #eee;
          margin-top: 8px;
          padding-top: 6px;
          font-size: 11px !important;
          color: #888;
          line-height: 1.3 !important;
        }
        
        .slider-panel-white {
          position: absolute !important;
          left: 20px !important;
          bottom: 20px !important;
          z-index: 1000 !important;
          width: 280px !important;
          background: white !important;  
          padding: 10px 12px !important;
          border-radius: 6px !important;
          box-shadow: 0 3px 12px rgba(0,0,0,0.2) !important;  
          color: #333 !important;  
         border: 1px solid #ccc !important;
        }
    
        .slider-panel-white .irs--shiny .irs-bar,
        .slider-panel-white .irs--shiny .irs-line {
          background: #ddd !important;
        }
    
        .slider-panel-white .irs--shiny .irs-handle {
          border-color: #3498DB !important;
          background: #3498DB !important;
        }
    
        .slider-panel-white .irs--shiny .irs-from,
        .slider-panel-white .irs--shiny .irs-to,
        .slider-panel-white .irs--shiny .irs-single {
          background: #3498DB !important;
          color: white !important;
        }
        
        .leaflet-control-scale {
          margin-bottom: 20px !important;
          margin-left: 20px !important;
        }
      "))
    ),
    
    tabItems(
      tabItem(tabName = "carte",
              tags$div(class = "custom-title-wrapper",
                       tags$div(class = "leaflet-control-custom-title",
                                tags$h4("Situation du Quai des Bateliers (Strasbourg)"),
                                tags$div(class = "sources",
                                         tags$p(tags$b("Sources:"), " Strasbourg Open Data, OSM, IGN, Mobiliscope"),
                                         tags$p("Discrétisation en quantiles")
                                )
                       )
              ),
              
              fluidRow(
                box(
                  width = 12,
                  solidHeader = FALSE,
                  status = "primary",
                  style = "padding: 0; margin: 0; height: calc(100vh - 50px);",
                  leafletOutput("carte", height = "calc(100vh - 50px)") 
                )
              )
      ),
      
      tabItem(tabName = "stats_comove",
              statistiques_ui
      ),
      
      tabItem(tabName = "mobilites",
              tags$div(class = "custom-title-wrapper",
                       tags$div(class = "leaflet-control-custom-title",
                                tags$h4("Réseau cyclable à Strasbourg"),
                                tags$div(class = "sources",
                                         tags$p(tags$b("Sources:"), " Strasbourg Open Data, OpenStreetMap"),
                                         tags$p("Les aménagements cyclables sans dates renseignées sont représentés par défaut")
                                )
                       )
              ),
              
              tags$div(class = "slider-panel-white",
                       tags$div(
                         style = "text-align:center; font-weight:bold; font-size:13px; margin-bottom:8px; color: #333;",
                         "Année de mise en service des aménagements cyclables"
                       ),
                       
                       sliderInput(
                         inputId = "date_amenagement",
                         min = floor(min(amg_cycl_sf$annee_service, na.rm = TRUE)),
                         max = ceiling(max(amg_cycl_sf$annee_service, na.rm = TRUE)),
                         value = max(amg_cycl_sf$annee_service, na.rm = TRUE),
                         step = 1,
                         ticks = TRUE,
                         animate = FALSE,
                         label = NULL,
                         sep = "",
                         width = "100%"
                       )
              ),
              
              fluidRow(
                box(
                  width = 12,
                  solidHeader = FALSE,
                  status = "primary",
                  style = "padding: 0; margin: 0; height: calc(100vh - 50px);",
                  leafletOutput("carte_mobilites", height = "calc(100vh - 50px)")
                )
              )
      ),
      
      tabItem(tabName = "temporelle",
              temporelle_ui
      ),
      
      tabItem(tabName = "donnees",
              div(style = "height: calc(100vh - 50px); overflow-y: auto;",
                  donnees_ui
              )
      ),
      
      tabItem(tabName = "ressenti",
              div(style = "height: calc(100vh - 50px); overflow-y: auto;",
                  ressenti_ui
              )
      )
    )
  )
)

server <- function(input, output, session) {
  
  observeEvent(input$toggle_sidebar, {
    shinyjs::toggleClass(selector = "body", class = "sidebar-collapsed")
  })
  
  output$carte <- renderLeaflet({
    
    colors_choropleth <- c("#FFFFCC", "#FFEDA0", "#FED976", "#FEB24C", "#FD8D3C")
    
    leaflet(options = leafletOptions(
      zoomControl = TRUE,
      attributionControl = FALSE  
    )) %>%
      
      addProviderTiles("CartoDB.Positron",
                       options = providerTileOptions(
                         attribution = ""
                       )) %>%
      
      addPolygons(
        data = districts_data,
        fillColor = ~colorFactor(colors_choropleth, actifs_classe)(actifs_classe),
        fillOpacity = 0.6,
        color = "grey",
        weight = 1,
        popup = ~paste("<b>Secteur ", LIB, "</b><br>",
                       "Part d'actifs: ", round(part_actifs, 1), "%<br>",
                       "Classe: ", actifs_classe, "<br>",
                       "Population: ", round(pop), " habitants")
      ) %>%
      
      addCircleMarkers(
        data = {
          centroids <- tryCatch({
            st_centroid(districts_data)
          }, error = function(e) {
            st_point_on_surface(districts_data)
          })
          centroids
        },
        radius = ~sqrt(pop) / 18,
        fillColor = "blue",
        color = "darkblue",
        weight = 1,
        fillOpacity = 0.7,
        popup = ~paste("<b>District ", CODE_SEC, "</b><br>",
                       "Population: ", round(pop), " habitants<br>",
                       "Part d'actifs: ", round(part_actifs, 1), "%")
      ) %>%
      
      addMarkers(
        lng = 7.753601, lat = 48.580602,
        popup = "<b>Quai des Bateliers</b><br>",
        icon = makeIcon(
          iconUrl = "https://cdn-icons-png.flaticon.com/512/684/684908.png",
          iconWidth = 24, iconHeight = 24,
          iconAnchorX = 12, iconAnchorY = 24
        )
      ) %>%
      
      addLegend(
        position = "bottomright",
        colors = colors_choropleth,
        labels = labels_choropleth,
        title = "Part d'actifs<br><span style='font-size: 11px;'>dans la population résidente</span>",
        opacity = 0.7
      ) %>%
      
      addControl(
        html = HTML(paste0(
          '<div class="circle-legend-container">
            <div class="circle-legend-title">Nombre d\'habitants</div>
            <div class="circle-legend-item">
              <div class="circle-sample" style="width: ', round(radius_breaks[2]*2), 'px; height: ', round(radius_breaks[2]*2), 'px;"></div>
              <span>', labels_circles[1], '</span>
            </div>
            <div class="circle-legend-item">
              <div class="circle-sample" style="width: ', round(radius_breaks[3]*2), 'px; height: ', round(radius_breaks[3]*2), 'px;"></div>
              <span>', labels_circles[2], '</span>
            </div>
            <div class="circle-legend-item">
              <div class="circle-sample" style="width: ', round(radius_breaks[4]*2), 'px; height: ', round(radius_breaks[4]*2), 'px;"></div>
              <span>', labels_circles[3], '</span>
            </div>
            <div class="circle-legend-item">
              <div class="circle-sample" style="width: ', round(radius_breaks[5]*2), 'px; height: ', round(radius_breaks[5]*2), 'px;"></div>
              <span>', labels_circles[4], '</span>
            </div>
          </div>'
        )),
        position = "bottomright"
      ) %>%
      
      addScaleBar(
        position = "bottomleft",
        options = scaleBarOptions(
          metric = TRUE,
          imperial = FALSE,
          maxWidth = 120
        )
      ) %>%
      
      setView(lng = 7.75, lat = 48.58, zoom = 12)
  })
  
  amenagements_filtres <- reactive({
    req(input$date_amenagement)
    
    amg_cycl_sf %>%
      filter(
        is.na(annee_service) | annee_service <= input$date_amenagement
      )
  })
  
  observe({
    req(input$date_amenagement)
    
    amg_filtered <- amenagements_filtres()
    
    if(nrow(amg_filtered) > 0) {
      leafletProxy("carte_mobilites") %>%
        clearGroup("Aménagements cyclables") %>%
        addPolylines(
          data = amg_filtered,
          color = ~colorFactor(
            palette = rainbow(length(unique(amg_filtered$ame_g))),
            domain = amg_filtered$ame_g
          )(ame_g),
          weight = 3,
          opacity = 0.9,
          group = "Aménagements cyclables",
          label = ~paste0(
            tools::toTitleCase(tolower(ame_g)),
            ifelse(
              !is.na(annee_service),
              paste0(" (", as.character(annee_service), ")"),
              " (Date inconnue)"
            )
          ),
          highlightOptions = highlightOptions(
            weight = 5,
            color = "#2C3E50",
            bringToFront = TRUE
          )
        )
    }
  })
  
  output$carte_mobilites <- renderLeaflet({
    
    amg_filtered <- amenagements_filtres()
    
    categories <- unique(amg_filtered$ame_g)
    palette_amenagements <- colorFactor(
      palette = rainbow(length(categories)),
      domain = categories
    )
    
    labels_amenagements <- sort(unique(amg_filtered$ame_g))
    labels_amenagements <- tools::toTitleCase(tolower(labels_amenagements))
    
    amg_colors <- rainbow(length(labels_amenagements))
    
    amg_legend_html <- ""
    for (i in seq_along(labels_amenagements)) {
      label_compact <- labels_amenagements[i]
      label_compact <- gsub("Cyclable", "Cycl.", label_compact)
      label_compact <- gsub("Chaussée", "Chauss.", label_compact)
      label_compact <- gsub("Centrale", "Centr.", label_compact)
      label_compact <- gsub("Couloir", "Coul.", label_compact)
      label_compact <- gsub("Double", "Dbl.", label_compact)
      label_compact <- gsub("Sens", "S.", label_compact)
      
      amg_legend_html <- paste0(amg_legend_html,
                                '<div style="margin-bottom: 3px; display: flex; align-items: center; min-height: 16px;">
        <i style="background:', amg_colors[i], '; width: 14px; height: 14px; display: inline-block; margin-right: 6px; flex-shrink: 0;"></i>
        <span style="font-size: 11px; line-height: 1.2; white-space: nowrap;">', 
                                label_compact, 
                                '</span>
      </div>'
      )
    }
    
    leaflet_map <- leaflet(options = leafletOptions(
      zoomControl = TRUE,
      attributionControl = FALSE
    )) %>%
      addProviderTiles("CartoDB.Positron") %>%
      
      addPolylines(
        data = amg_filtered,
        color = ~palette_amenagements(ame_g), 
        weight = 3,
        opacity = 0.9,
        group = "Aménagements cyclables",
        label = ~paste0(
          tools::toTitleCase(tolower(ame_g)),
          ifelse(
            !is.na(annee_service),
            paste0(" (", as.character(annee_service), ")"),
            " (Date inconnue)"
          )
        ),
        highlightOptions = highlightOptions(
          weight = 5,
          color = "#2C3E50",
          bringToFront = TRUE
        )
      ) %>%
      
      addPolylines(
        data = flux_voies,
        color = "black",
        weight = ~case_when(
          etat == 1 ~ 3,
          etat == 2 ~ 5,
          etat == 3 ~ 7,
          TRUE ~ 3
        ),
        opacity = 0.8,
        group = "Flux de trafic",
        label = ~paste("Trafic: niveau", etat)
      ) %>%
      
      addCircleMarkers(
        data = stations_sf,
        radius = 8,
        fillColor = "white",
        color = "black",
        weight = 4,
        fillOpacity = 0.9,
        stroke = TRUE,
        group = "Stations VELHOP",
        label = ~name,
        popup = ~paste0(
          "<b>Station: ", name, "</b><br>",
          "ID: ", station_id, "<br>",
          "Capacité: ", capacity, " vélos"
        ),
        options = markerOptions(zIndexOffset = 1000)
      ) %>%
      
      addMarkers(
        lng = 7.753601, lat = 48.580602,
        popup = "<b>Quai des Bateliers</b>",
        group = "Quai des Bateliers"
      ) %>%
      
      addControl(
        position = "bottomright",
        html = HTML(paste0('
        <div style="
          background: white;
          padding: 10px 12px;
          border-radius: 5px;
          border: 1px solid #ccc;
          box-shadow: 0 2px 6px rgba(0,0,0,0.15);
          font-size: 12px;
          max-width: 220px;
        ">
          <div style="margin-bottom: 8px;">
            <div style="font-weight: bold; font-size: 13px; margin-bottom: 4px; border-bottom: 1px solid #ddd; padding-bottom: 3px; color: #333;">
              Stations VELHOP
            </div>
            <div style="display: flex; align-items: center; margin-bottom: 3px;">
              <div style="width: 14px; height: 14px; border-radius: 50%; background-color: white; border: 2px solid black; margin-right: 8px; flex-shrink: 0;"></div>
              <span style="font-size: 11px; line-height: 1.2;">Vélos libre-service</span>
            </div>
          </div>
          
          <div style="margin-bottom: 8px;">
            <div style="font-weight: bold; font-size: 13px; margin-bottom: 4px; border-bottom: 1px solid #ddd; padding-bottom: 3px; color: #333;">
              Intensité trafic
            </div>
            <div style="margin-bottom: 3px;">
              <div style="display: flex; align-items: center; margin-bottom: 3px;">
                <div style="width: 24px; height: 2px; background-color: black; margin-right: 8px; flex-shrink: 0;"></div>
                <span style="font-size: 11px; line-height: 1.2;">Faible</span>
              </div>
              <div style="display: flex; align-items: center; margin-bottom: 3px;">
                <div style="width: 24px; height: 3px; background-color: black; margin-right: 8px; flex-shrink: 0;"></div>
                <span style="font-size: 11px; line-height: 1.2;">Moyen</span>
              </div>
              <div style="display: flex; align-items: center; margin-bottom: 3px;">
                <div style="width: 24px; height: 4px; background-color: black; margin-right: 8px; flex-shrink: 0;"></div>
                <span style="font-size: 11px; line-height: 1.2;">Élevé</span>
              </div>
            </div>
          </div>
          
          <div>
            <div style="font-weight: bold; font-size: 13px; margin-bottom: 4px; border-bottom: 1px solid #ddd; padding-bottom: 3px; color: #333;">
              Aménagements
            </div>
            <div style="padding-right: 4px;">
              ', amg_legend_html, '
            </div>
          </div>
        </div>
      '))
      ) %>%
      
      addScaleBar(
        position = "topleft",
        options = scaleBarOptions(
          metric = TRUE,
          imperial = FALSE,
          maxWidth = 150
        )
      ) %>%
      
      setView(lng = 7.75, lat = 48.58, zoom = 13)
    
    leaflet_map
  })
  
  observe({
    updateSliderInput(
      session,
      "date_amenagement",
      value = max(amg_cycl_sf$annee_service, na.rm = TRUE)
    )
  })
  
  format_no_decimals <- function(x) {
    if(is.numeric(x)) {
      return(as.integer(round(x)))
    }
    return(x)
  }
  
  output$camembert_plot <- renderPlot({
    variable_camembert <- switch(input$select_camembert,
                                 "Genre" = "Genre",
                                 "Âge" = "Classe_age",
                                 "Mode de transport" = "Mode_transport")
    
    if (variable_camembert == "Genre") {
      donnees_camembert <- enquete_data %>%
        filter(!is.na(Genre) & Genre != "Non spécifié") %>%
        group_by(Genre) %>%
        summarise(count = n()) %>%
        mutate(
          count = format_no_decimals(count),
          percentage = round(count/sum(count) * 100),
          label = paste0(Genre, "\n", count, " (", percentage, "%)")
        )
      
      couleurs <- c("#3498DB", "#E74C3C", "#2ECC71")
      fill_var <- sym("Genre")
      
    } else if (variable_camembert == "Classe_age") {
      donnees_camembert <- enquete_data %>%
        filter(!is.na(Classe_age) & Classe_age != "Non spécifié") %>%
        group_by(Classe_age) %>%
        summarise(count = n()) %>%
        mutate(
          count = format_no_decimals(count),
          percentage = round(count/sum(count) * 100),
          label = paste0(Classe_age, "\n", count, " (", percentage, "%)")
        )
      
      couleurs <- c("#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7")
      fill_var <- sym("Classe_age")
      
    } else { 
      donnees_camembert <- enquete_data %>%
        filter(!is.na(Mode_transport) & Mode_transport != "Non spécifié") %>%
        group_by(Mode_transport) %>%
        summarise(count = n()) %>%
        mutate(
          count = format_no_decimals(count),
          percentage = round(count/sum(count) * 100),
          label = paste0(Mode_transport, "\n", count, " (", percentage, "%)")
        )
      
      couleurs <- c("#9B59B6", "#1ABC9C", "#F39C12")
      fill_var <- sym("Mode_transport")
    }
    
    titre <- switch(variable_camembert,
                    "Genre" = "Répartition par genre",
                    "Classe_age" = "Répartition par âge",
                    "Mode_transport" = "Répartition par mode de transport")
    
    ggplot(donnees_camembert, aes(x = 2, y = count, fill = !!fill_var)) +
      geom_bar(stat = "identity", width = 1) +
      coord_polar("y", start = 0) +
      xlim(0.5, 2.5) +
      
      scale_fill_manual(
        values = couleurs,
        name = ifelse(variable_camembert == "Classe_age", "Âge", 
                      ifelse(variable_camembert == "Genre", "Genre", "Mode de transport"))
      ) +
      
      geom_text(
        aes(label = paste0(percentage, "%")), 
        position = position_stack(vjust = 0.5),
        size = 4, 
        fontface = "bold", 
        color = "black"
      ) +
      
      labs(
        title = titre,
        subtitle = paste("Total :", sum(donnees_camembert$count), "réponses")
      ) +
      
      theme_void() +
      theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40", lineheight = 1.2),
        legend.position = "right",
        legend.title = element_text(size = 12, face = "bold"),
        legend.text = element_text(size = 11)
      )
  })
  
  output$bar_age_plot <- renderPlot({
    donnees_bar_age <- enquete_data %>%
      filter(!is.na(Mode_transport) & Mode_transport != "Non spécifié" & 
               !is.na(Classe_age) & Classe_age != "Non spécifié") %>%
      group_by(Mode_transport, Classe_age) %>%
      summarise(count = n(), .groups = 'drop') %>%
      mutate(count = format_no_decimals(count)) %>%
      group_by(Mode_transport) %>%
      mutate(
        total_mode = sum(count),
        percent = round(count/total_mode * 100)
      ) %>%
      ungroup() %>%
      arrange(Mode_transport, desc(Classe_age)) %>%
      group_by(Mode_transport) %>%
      mutate(
        ypos = cumsum(count) - 0.5 * count
      ) %>%
      ungroup()
    
    age_totals <- donnees_bar_age %>%
      group_by(Classe_age) %>%
      summarise(total_age = sum(count), .groups = 'drop')
    
    ggplot(donnees_bar_age, aes(x = Mode_transport, y = count, fill = Classe_age)) +
      geom_bar(stat = "identity", position = "stack", alpha = 0.9, color = "black", linewidth = 0.5) +
      
      geom_text(
        aes(y = ypos, label = count),
        color = "white",
        size = 4,
        fontface = "bold",
        vjust = 0.5
      ) +
      
      geom_text(
        data = donnees_bar_age %>% 
          group_by(Mode_transport) %>% 
          summarise(total = sum(count), .groups = 'drop'),
        aes(x = Mode_transport, y = total, label = paste("Total:", total)),
        inherit.aes = FALSE,
        vjust = -0.5,
        color = "black",
        size = 4,
        fontface = "bold"
      ) +
      
      scale_fill_manual(
        values = c("0-20 ans" = "#FF6B6B", 
                   "20-40 ans" = "#4ECDC4", 
                   "40-60 ans" = "#45B7D1", 
                   "60+ ans" = "#96CEB4"),
        name = "Âge",
        labels = function(x) {
          sapply(x, function(age) {
            total <- age_totals$total_age[age_totals$Classe_age == age]
            paste0(age, " (n=", total, ")")
          })
        }
      ) +
      
      labs(
        title = "Répartition des modes de transport par âge",
        x = NULL,
        y = "Nombre d'enquêtés"
      ) +
      
      theme_minimal() +
      theme(
        plot.title = element_text(size = 14, face = "bold", hjust = 0.5, margin = margin(b = 10)),
        axis.title.y = element_text(size = 12, face = "bold", margin = margin(r = 10)),
        axis.text = element_text(size = 11),
        axis.text.x = element_text(face = "bold", size = 11),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.grid.major.y = element_line(color = "gray90", linewidth = 0.3),
        panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "white", color = NA),
        legend.position = "right",
        legend.title = element_text(size = 11, face = "bold"),
        legend.text = element_text(size = 10)
      ) +
      
      scale_y_continuous(expand = expansion(mult = c(0, 0.15)))
  })
  
  output$bar_genre_plot <- renderPlot({
    donnees_bar_genre <- enquete_data %>%
      filter(!is.na(Mode_transport) & Mode_transport != "Non spécifié" & 
               !is.na(Genre) & Genre != "Non spécifié") %>%
      group_by(Mode_transport, Genre) %>%
      summarise(count = n(), .groups = 'drop') %>%
      mutate(count = format_no_decimals(count)) %>%
      group_by(Mode_transport) %>%
      mutate(
        total_mode = sum(count),
        percent = round(count/total_mode * 100)
      ) %>%
      ungroup() %>%
      arrange(Mode_transport, desc(Genre)) %>%
      group_by(Mode_transport) %>%
      mutate(
        ypos = cumsum(count) - 0.5 * count
      ) %>%
      ungroup()
    
    genre_totals <- donnees_bar_genre %>%
      group_by(Genre) %>%
      summarise(total_genre = sum(count), .groups = 'drop')
    
    ggplot(donnees_bar_genre, aes(x = Mode_transport, y = count, fill = Genre)) +
      geom_bar(stat = "identity", position = "stack", alpha = 0.9, color = "black", linewidth = 0.5) +
      
      geom_text(
        aes(y = ypos, label = count),
        color = "white",
        size = 4,
        fontface = "bold",
        vjust = 0.5
      ) +
      
      geom_text(
        data = donnees_bar_genre %>% 
          group_by(Mode_transport) %>% 
          summarise(total = sum(count), .groups = 'drop'),
        aes(x = Mode_transport, y = total, label = paste("Total:", total)),
        inherit.aes = FALSE,
        vjust = -0.5,
        color = "black",
        size = 4,
        fontface = "bold"
      ) +
      
      scale_fill_manual(
        values = c("Homme" = "#FF0000", "Femme" = "#3498DB"),
        name = "Genre",
        labels = function(x) {
          sapply(x, function(g) {
            total <- genre_totals$total_genre[genre_totals$Genre == g]
            paste0(g, " (n=", total, ")")
          })
        }
      ) +
      
      labs(
        title = "Répartition des modes de transport par genre",
        x = NULL,
        y = "Nombre d'enquêtés"
      ) +
      
      theme_minimal() +
      theme(
        plot.title = element_text(size = 14, face = "bold", hjust = 0.5, margin = margin(b = 10)),
        axis.title.y = element_text(size = 12, face = "bold", margin = margin(r = 10)),
        axis.text = element_text(size = 11),
        axis.text.x = element_text(face = "bold", size = 11),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.grid.major.y = element_line(color = "gray90", linewidth = 0.3),
        panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "white", color = NA),
        legend.position = "right",
        legend.title = element_text(size = 11, face = "bold"),
        legend.text = element_text(size = 10)
      ) +
      
      scale_y_continuous(expand = expansion(mult = c(0, 0.15)))
  })
  
  output$total_deplacements <- renderText({
    req(enquete_data)
    total <- nrow(enquete_data %>% filter(!is.na(Heure) & Heure != ""))
    paste("Total des déplacements analysés :", total)
  })
  
  output$temp_plot <- renderPlot({
    req(enquete_data)
    
    if(input$categorie_selector == "motif") {
      motif_col <- ifelse("Motif_deplacement" %in% names(enquete_data), 
                          "Motif_deplacement", 
                          ifelse("Motif" %in% names(enquete_data), "Motif", NA))
      
      if(is.na(motif_col)) {
        return(ggplot() +
                 annotate("text", x = 0.5, y = 0.5, 
                          label = "Colonne 'Motif de déplacement' non trouvée", 
                          size = 6) +
                 theme_void())
      }
      
      data_plot <- enquete_data %>%
        mutate(
          Heure_num = as.numeric(sub(":.*", "", Heure)),
          Heure_num = ifelse(Heure_num >= 8 & Heure_num <= 19, Heure_num, NA)
        ) %>%
        filter(!is.na(Heure_num)) %>%
        mutate(
          Categorie = case_when(
            grepl("travail|études|travail/études", .data[[motif_col]], ignore.case = TRUE) ~ "Travail/Études",
            grepl("promenade|loisir|activites/loisirs", .data[[motif_col]], ignore.case = TRUE) ~ "Loisirs/Promenade",
            grepl("autre", .data[[motif_col]], ignore.case = TRUE) ~ "Autre",
            .data[[motif_col]] %in% c("", "null", "NULL", "sans réponse", "sans reponse") ~ "Non spécifié",
            TRUE ~ "Autre"
          )
        ) %>%
        group_by(Heure_num, Categorie) %>%
        summarise(n = n(), .groups = 'drop') %>%
        mutate(n = format_no_decimals(n)) %>%
        group_by(Heure_num) %>%
        mutate(
          total_heure = sum(n),
          pourcentage = round(n / total_heure * 100)
        ) %>%
        ungroup() %>%
        mutate(Categorie = factor(Categorie, 
                                  levels = c("Travail/Études", "Loisirs/Promenade", "Autre", "Non spécifié")))
      
      couleurs <- c("Travail/Études" = "#3498DB", 
                    "Loisirs/Promenade" = "#2ECC71", 
                    "Autre" = "#F39C12", 
                    "Non spécifié" = "#95A5A6")
      
      titre <- "Répartition des motifs de déplacement par heure (8h-19h)"
      legende <- "Motif"
      
    } else if(input$categorie_selector == "transport") {
      data_plot <- enquete_data %>%
        mutate(
          Heure_num = as.numeric(sub(":.*", "", Heure)),
          Heure_num = ifelse(Heure_num >= 8 & Heure_num <= 19, Heure_num, NA)
        ) %>%
        filter(!is.na(Heure_num) & !is.na(Mode_transport) & Mode_transport != "" & !grepl("sans|Sans|null|NULL", Mode_transport, ignore.case = TRUE)) %>%
        mutate(
          Categorie = case_when(
            grepl("piéton|pieton", Mode_transport, ignore.case = TRUE) ~ "Piéton",
            grepl("cycliste|cycl", Mode_transport, ignore.case = TRUE) ~ "Cycliste",
            TRUE ~ "Autre"
          )
        ) %>%
        group_by(Heure_num, Categorie) %>%
        summarise(n = n(), .groups = 'drop') %>%
        mutate(n = format_no_decimals(n)) %>%
        group_by(Heure_num) %>%
        mutate(
          total_heure = sum(n),
          pourcentage = round(n / total_heure * 100)
        ) %>%
        ungroup() %>%
        mutate(Categorie = factor(Categorie, 
                                  levels = c("Piéton", "Cycliste", "Autre")))
      
      couleurs <- c("Piéton" = "#3498DB", 
                    "Cycliste" = "#2ECC71", 
                    "Autre" = "#F39C12")
      
      titre <- "Répartition des modes de transport par heure (8h-19h)"
      legende <- "Mode de transport"
      
    } else if(input$categorie_selector == "age") {
      data_plot <- enquete_data %>%
        mutate(
          Heure_num = as.numeric(sub(":.*", "", Heure)),
          Heure_num = ifelse(Heure_num >= 8 & Heure_num <= 19, Heure_num, NA)
        ) %>%
        filter(!is.na(Heure_num) & !is.na(Classe_age) & Classe_age != "Non spécifié") %>%
        mutate(
          Categorie = Classe_age
        ) %>%
        group_by(Heure_num, Categorie) %>%
        summarise(n = n(), .groups = 'drop') %>%
        mutate(n = format_no_decimals(n)) %>%
        group_by(Heure_num) %>%
        mutate(
          total_heure = sum(n),
          pourcentage = round(n / total_heure * 100)
        ) %>%
        ungroup() %>%
        mutate(Categorie = factor(Categorie, 
                                  levels = c("0-20 ans", "20-40 ans", "40-60 ans", "60+ ans")))
      
      couleurs <- c("0-20 ans" = "#FF6B6B", 
                    "20-40 ans" = "#4ECDC4", 
                    "40-60 ans" = "#45B7D1", 
                    "60+ ans" = "#96CEB4")
      
      titre <- "Répartition par classe d'âge par heure (8h-19h)"
      legende <- "Classe d'âge"
      
    } else if(input$categorie_selector == "genre") {
      data_plot <- enquete_data %>%
        mutate(
          Heure_num = as.numeric(sub(":.*", "", Heure)),
          Heure_num = ifelse(Heure_num >= 8 & Heure_num <= 19, Heure_num, NA)
        ) %>%
        filter(!is.na(Heure_num) & !is.na(Genre) & Genre != "Non spécifié") %>%
        mutate(
          Categorie = Genre
        ) %>%
        group_by(Heure_num, Categorie) %>%
        summarise(n = n(), .groups = 'drop') %>%
        mutate(n = format_no_decimals(n)) %>%
        group_by(Heure_num) %>%
        mutate(
          total_heure = sum(n),
          pourcentage = round(n / total_heure * 100)
        ) %>%
        ungroup() %>%
        mutate(Categorie = factor(Categorie, 
                                  levels = c("Femme", "Homme")))
      
      couleurs <- c("Homme" = "#FF0000", "Femme" = "#3498DB")
      
      titre <- "Répartition par genre par heure (8h-19h)"
      legende <- "Genre"
    }
    
    if(nrow(data_plot) == 0) {
      return(ggplot() +
               annotate("text", x = 0.5, y = 0.5, 
                        label = "Aucune donnée disponible pour la période 8h-19h", 
                        size = 6) +
               theme_void())
    }
    
    ggplot(data_plot, aes(x = factor(Heure_num), y = pourcentage, fill = Categorie)) +
      geom_bar(stat = "identity", position = "fill", width = 0.7) +
      scale_fill_manual(values = couleurs, name = legende) +
      
      geom_text(aes(label = ifelse(pourcentage > 10, paste0(pourcentage, "%"), "")), 
                position = position_fill(vjust = 0.5), 
                color = "white", 
                size = 3.5, 
                fontface = "bold") +
      
      geom_text(data = data_plot %>% 
                  group_by(Heure_num) %>% 
                  summarise(total = first(total_heure), .groups = 'drop'),
                aes(x = factor(Heure_num), y = 1.05, label = paste("n =", total)),
                inherit.aes = FALSE,
                size = 3.5,
                fontface = "bold",
                color = "#2C3E50") +
      
      labs(
        title = titre,
        x = "Heure",
        y = "Pourcentage (%)",
        caption = "Données de l'enquête Co-Move 2025"
      ) +
      
      theme_minimal() +
      theme(
        plot.title = element_text(size = 18, face = "bold", hjust = 0.5, margin = margin(b = 15)),
        axis.title.x = element_text(size = 14, face = "bold", margin = margin(t = 10)),
        axis.title.y = element_text(size = 14, face = "bold", margin = margin(r = 10)),
        axis.text.x = element_text(size = 12, angle = 0, hjust = 0.5),
        axis.text.y = element_text(size = 11),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "gray90", linewidth = 0.5),
        panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "white", color = NA),
        plot.caption = element_text(size = 10, color = "gray60", hjust = 1, margin = margin(t = 10)),
        legend.position = "bottom",
        legend.title = element_text(size = 12, face = "bold"),
        legend.text = element_text(size = 11),
        legend.key.size = unit(0.8, "cm")
      ) +
      
      scale_x_discrete(labels = function(x) paste0(x, "h")) +
      scale_y_continuous(labels = scales::percent_format(scale = 1), 
                         expand = expansion(mult = c(0, 0.15)),
                         breaks = seq(0, 100, by = 25))
  })
  
  nettoyer_ressenti <- function(data) {
    data %>%
      mutate(
        Sentiment_securite = case_when(
          tolower(Sentiment_securite) %in% c("tout à fait d'accord", "tout a fait d'accord") ~ "Sécurité élevée",
          tolower(Sentiment_securite) %in% c("plutôt d'accord", "plutot d'accord") ~ "Sécurité moyenne",
          tolower(Sentiment_securite) %in% c("plutôt pas d'accord", "plutot pas d'accord") ~ "Sécurité faible",
          tolower(Sentiment_securite) %in% c("pas du tout d'accord") ~ "Insécurité",
          tolower(Sentiment_securite) %in% c("ne sait pas", "sans reponse", "null", "") ~ "Non spécifié",
          TRUE ~ "Non spécifié"
        ),
        
        Perception_risque_collision_pietons_cyclistes = case_when(
          tolower(Perception_risque_collision_pietons_cyclistes) %in% c("tout à fait d'accord", "tout a fait d'accord") ~ "Risque très faible",
          tolower(Perception_risque_collision_pietons_cyclistes) %in% c("plutôt d'accord", "plutot d'accord") ~ "Risque faible",
          tolower(Perception_risque_collision_pietons_cyclistes) %in% c("plutôt pas d'accord", "plutot pas d'accord") ~ "Risque moyen",
          tolower(Perception_risque_collision_pietons_cyclistes) %in% c("pas du tout d'accord") ~ "Risque élevé",
          tolower(Perception_risque_collision_pietons_cyclistes) %in% c("ne sait pas", "sans reponse", "null", "") ~ "Non spécifié",
          TRUE ~ "Non spécifié"
        ),
        
        Perception_tensions = case_when(
          tolower(Perception_tensions) %in% c("tout à fait d'accord", "tout a fait d'accord") ~ "Tensions fortes", 
          tolower(Perception_tensions) %in% c("plutôt d'accord", "plutot d'accord") ~ "Tensions moyennes", 
          tolower(Perception_tensions) %in% c("plutôt pas d'accord", "plutot pas d'accord") ~ "Tensions faibles", 
          tolower(Perception_tensions) %in% c("pas du tout d'accord") ~ "Pas de tensions", 
          tolower(Perception_tensions) %in% c("ne sait pas", "sans reponse", "null", "") ~ "Non spécifié",
          TRUE ~ "Non spécifié"
        ),
        
        Frequence_clean = case_when(
          tolower(Frequence) %in% c("tous les jours", "tous les jours") ~ "Quotidien",
          tolower(Frequence) %in% c("toutes les semaines", "toutes les semaines") ~ "Hebdomadaire",
          tolower(Frequence) %in% c("moins souvent") ~ "Occasionnel",
          tolower(Frequence) %in% c("premiere fois") ~ "Première fois",
          tolower(Frequence) %in% c("sans reponse", "null", "") ~ "Non spécifié",
          TRUE ~ as.character(Frequence)
        )
      )
  }
  
  generate_bubble_plot <- function(data, var_name, facet_var, title) {
    data_prep <- data %>%
      mutate(
        var_value = case_when(
          var_name == "Sentiment_securite" ~ Sentiment_securite,
          var_name == "Perception_risque_collision_pietons_cyclistes" ~ Perception_risque_collision_pietons_cyclistes,
          var_name == "Perception_tensions" ~ Perception_tensions,
          TRUE ~ Sentiment_securite
        )
      ) %>%
      filter(!is.na(var_value) & var_value != "Non spécifié")
    
    if(facet_var == "Mode_transport") {
      data_prep <- data_prep %>%
        filter(!is.na(Mode_transport) & Mode_transport != "Non spécifié") %>%
        group_by(Mode_transport, var_value) %>%
        summarise(count = n(), .groups = 'drop') %>%
        mutate(count = format_no_decimals(count))
      
      fill_var <- "Mode_transport"
      
      transport_levels <- unique(data_prep$Mode_transport)
      colors <- setNames(
        c("#3498DB", "#E74C3C", "#2ECC71", "#9B59B6", "#F39C12")[1:length(transport_levels)],
        transport_levels
      )
      
    } else if(facet_var == "Genre") {
      data_prep <- data_prep %>%
        filter(!is.na(Genre) & Genre != "Non spécifié") %>%
        group_by(Genre, var_value) %>%
        summarise(count = n(), .groups = 'drop') %>%
        mutate(count = format_no_decimals(count))
      
      fill_var <- "Genre"
      colors <- c("Femme" = "#3498DB", "Homme" = "#2ECC71")
      
    } else if(facet_var == "Frequence_clean") {
      data_prep <- data_prep %>%
        filter(!is.na(Frequence_clean) & Frequence_clean != "Non spécifié") %>%
        group_by(Frequence_clean, var_value) %>%
        summarise(count = n(), .groups = 'drop') %>%
        mutate(count = format_no_decimals(count))
      
      fill_var <- "Frequence_clean"
      colors <- c("Quotidien" = "#E67E22", "Hebdomadaire" = "#1ABC9C", 
                  "Occasionnel" = "#F1C40F", "Première fois" = "#E74C3C")
      
    } else if(facet_var == "Classe_age") {
      data_prep <- data_prep %>%
        filter(!is.na(Classe_age) & Classe_age != "Non spécifié") %>%
        group_by(Classe_age, var_value) %>%
        summarise(count = n(), .groups = 'drop') %>%
        mutate(count = format_no_decimals(count))
      
      fill_var <- "Classe_age"
      colors <- c("0-20 ans" = "#FF6B6B", "20-40 ans" = "#4ECDC4", 
                  "40-60 ans" = "#45B7D1", "60+ ans" = "#96CEB4")
    }
    
    data_prep <- data_prep %>%
      filter(count > 0)
    
    if(var_name == "Sentiment_securite") {
      data_prep <- data_prep %>%
        mutate(var_value = factor(var_value, 
                                  levels = c("Insécurité", "Sécurité faible", 
                                             "Sécurité moyenne", "Sécurité élevée")))
    } else if(var_name == "Perception_risque_collision_pietons_cyclistes") {
      data_prep <- data_prep %>%
        mutate(var_value = factor(var_value,
                                  levels = c("Risque très faible", "Risque faible", 
                                             "Risque moyen", "Risque élevé")))
    } else if(var_name == "Perception_tensions") {
      data_prep <- data_prep %>%
        mutate(var_value = factor(var_value,
                                  levels = c("Pas de tensions", "Tensions faibles", 
                                             "Tensions moyennes", "Tensions fortes")))
    }
    
    max_count <- max(data_prep$count, na.rm = TRUE)
    size_range <- if(max_count > 50) c(10, 25) else c(8, 20)
    
    p <- ggplot(data_prep, aes(x = var_value, y = count)) +
      geom_point(aes(size = count, color = !!sym(fill_var)), alpha = 0.7) +
      geom_text(aes(label = count), size = 3.5, vjust = -1.5, fontface = "bold") +
      
      scale_size_continuous(
        name = "Nombre\nd'observations",
        range = size_range,
        breaks = function(x) {
          if(length(unique(x)) > 1) {
            pretty(x, n = min(4, length(unique(x))))
          } else {
            unique(x)
          }
        }
      ) +
      
      scale_color_manual(
        values = colors,
        name = ifelse(facet_var == "Frequence_clean", "Fréquence", 
                      ifelse(facet_var == "Classe_age", "Âge",
                             ifelse(facet_var == "Genre", "Genre", "Mode de transport")))
      ) +
      
      labs(
        title = title,
        x = switch(var_name,
                   "Sentiment_securite" = "Sentiment de sécurité",
                   "Perception_risque_collision_pietons_cyclistes" = "Perception du risque de collision",
                   "Perception_tensions" = "Perception des tensions"),
        y = "Nombre d'observations"
      ) +
      
      theme_minimal() +
      theme(
        plot.title = element_text(size = 14, face = "bold", hjust = 0.5, margin = margin(b = 15)),
        axis.title.x = element_text(size = 12, face = "bold", margin = margin(t = 10)),
        axis.title.y = element_text(size = 12, face = "bold", margin = margin(r = 10)),
        axis.text.x = element_text(size = 11, angle = 0, hjust = 0.5, vjust = 1),
        axis.text.y = element_text(size = 10),
        legend.position = "right",
        legend.title = element_text(size = 10, face = "bold"),
        legend.text = element_text(size = 9),
        legend.box = "vertical",
        legend.margin = margin(l = 0, r = 0),
        legend.spacing.y = unit(0.2, "cm"),
        panel.grid.major = element_line(color = "gray90", linewidth = 0.2),
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "white", color = NA),
        plot.margin = margin(10, 20, 10, 10)
      ) +
      
      guides(
        color = guide_legend(
          override.aes = list(size = 4),
          title.position = "top",
          title.hjust = 0.5
        ),
        size = guide_legend(
          title.position = "top",
          title.hjust = 0.5
        )
      ) +
      
      scale_y_continuous(
        limits = c(0, max(data_prep$count) * 1.3),
        expand = expansion(mult = c(0.05, 0.15))
      )
    
    return(p)
  }
  
  output$ressenti_mode_plot <- renderPlot({
    req(enquete_data, input$var_mode)
    
    data_clean <- nettoyer_ressenti(enquete_data) %>%
      filter(Mode_transport != "Non spécifié")
    
    generate_bubble_plot(
      data = data_clean,
      var_name = input$var_mode,
      facet_var = "Mode_transport",
      title = "Distribution du ressenti par mode de transport"
    )
  })
  
  output$ressenti_genre_plot <- renderPlot({
    req(enquete_data, input$var_genre)
    
    data_clean <- nettoyer_ressenti(enquete_data) %>%
      filter(Genre != "Non spécifié")
    
    generate_bubble_plot(
      data = data_clean,
      var_name = input$var_genre,
      facet_var = "Genre",
      title = "Distribution du ressenti par genre"
    )
  })
  
  output$ressenti_freq_plot <- renderPlot({
    req(enquete_data, input$var_freq)
    
    data_clean <- nettoyer_ressenti(enquete_data) %>%
      filter(Frequence_clean != "Non spécifié")
    
    generate_bubble_plot(
      data = data_clean,
      var_name = input$var_freq,
      facet_var = "Frequence_clean",
      title = "Distribution du ressenti par fréquence d'utilisation"
    )
  })
  
  output$ressenti_age_plot <- renderPlot({
    req(enquete_data, input$var_age)
    
    data_clean <- nettoyer_ressenti(enquete_data) %>%
      filter(Classe_age != "Non spécifié")
    
    generate_bubble_plot(
      data = data_clean,
      var_name = input$var_age,
      facet_var = "Classe_age",
      title = "Distribution du ressenti par classe d'âge"
    )
  })
  
}

shinyApp(ui = ui, server = server)