library(sf)
library(RPostgreSQL)
library(RColorBrewer)
library(classInt)
library(leaflet)
library(glue)

con <- dbConnect("PostgreSQL", dbname = "projet_velos",
                 user = "projet_velos", password = "ab*rERp#Wz6m", host="193.55.175.126" ,port="2002")

requ4 <- read_sf(con, query = "select trajet, st_makeline(ls.geom, lr.geom) as geometry, nb_trajet, lr.x as x_r,lr.y as y_r
from
(select id_lieu_s,id_lieu_r, trajet, count (trajet) as nb_trajet 
from velo, lieu, ville 
where nom_ville = 'Lyon' and ville.id_ville = lieu.id_ville
	and nom_lieu = 'Bourse Du Travail' and velo.id_lieu_s = lieu.id_lieu
		and annee_s = 2019
		and mois_s >= 1 and mois_s <= 1
		and jour_s >= 1 and jour_s <= 1
		and heure_s >= 0 and heure_s <= 24
		and minute_s >= 0 and minute_s <= 60
 group by trajet,id_lieu_s,id_lieu_r) as t
inner join lieu as ls on t.id_lieu_s = ls.id_lieu
inner join lieu as lr on t.id_lieu_r = lr.id_lieu
where nb_trajet >= 1
                                ")


# Disconnect from the DB
dbDisconnect(con)

# Convert to data.frame
#data.frame(requ4)

# Symbologie couleur
library(RColorBrewer)
# Choix de la couleur de la palette
pall = brewer.pal(n= 9,name = 'YlOrRd')
# choix méthode de discrétisation + calcul des breaks
library(classInt)
ci=classIntervals(requ4$nb_trajet, 4, style = "jenks")
# fonction qui permet d'attribuer la couleur
pal <- colorBin(
  palette = pall,
  domain = requ4$nb_trajet,
  reverse = FALSE,
  bins=ci$brks
)#qui permet de definir la couleur
col=pal(requ4$nb_trajet)

# Render map

map<- leaflet(requ4) %>% 
    addProviderTiles(providers$CartoDB.Positron)%>%
    addPolylines (data = requ4$geometry, weight = requ4$nb_trajet*2,
                  opacity = 1, color=col)
    addCircles(map= map, lng = ~requ4$x_r, lat = ~requ4$y_r, radius= requ4$nb_trajet*50, fillOpacity = 0.8 ,fillColor= col, color="#000", opacity = 0.8, weight = 1)%>%
    addLegend( 
      title = "Nombre de trajet",
      pal = pal, values = requ4$nb_trajet, opacity=0.8)
    
  