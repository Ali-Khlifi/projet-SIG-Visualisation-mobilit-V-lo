rm(list = ls())

library(RPostgreSQL)
connexion <- dbConnect("PostgreSQL", dbname = "projet_velos",
                       user = "projet_velos", password = "ab*rERp#Wz6m", host="193.55.175.126" ,port="2002")
library(sf)

sf <- read_sf(connexion, query = "select troncons.link_id, st_name, geom, count(enr_gps_simple.link_id) as dens
from enr_gps_simple, troncons, ville
where enr_gps_simple.link_id = troncons.link_id and enr_gps_simple.id_ville = ville.id_ville
and nom_ville ='Toulouse'
and annee = 2019 
and mois >= 1 and mois <= 1
and jour >= 1 and jour <= 1
and heure >= 8 and heure <= 9
and minute >= 0 and minute <= 60
group by st_name, geom, troncons.link_id
 ")

# Représentation avec symbologie couleur
library(RColorBrewer)

# Choix de la couleur de la palette
pall = brewer.pal(n= 9,name = 'YlOrRd')

# choix méthode de discrétisation + calcul des breaks
library(classInt)
ci=classIntervals(sf$dens, 4, style = "jenks")

# fonction qui permet d'attribuer la couleur
library(leaflet)
pal <- colorBin(
  palette = pall,
  domain = sf$dens,
  reverse = FALSE,
  bins=ci$brks
)

# on applique la couleur sur le champ dens
col=pal(sf$dens)

# paramétrage de la carte
leaflet(sf) %>% 
  addProviderTiles(providers$CartoDB.Positron) %>% 
  addPolylines(color = col, weight = 2,smoothFactor = 0.5,
               opacity = 0.8, fillOpacity = 1, label = sf$dens) %>% 
  addLegend(
    title = "Nb signal gps/tronçon",
    pal = pal, values = sf$dens, opacity = 0.8)
