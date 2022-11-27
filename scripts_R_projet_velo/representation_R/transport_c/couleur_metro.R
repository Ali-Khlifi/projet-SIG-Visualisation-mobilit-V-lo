library(RPostgreSQL)
con <- dbConnect("PostgreSQL", dbname = "projet_velos",
                       user = "projet_velos", password = "ab*rERp#Wz6m", host="193.55.175.126" ,port="2002")
library(sf)

requ4 <- dbSendQuery(con, "select nom_lieu,x, y, sum(nb_valid) as nb_valid
from lieu, tc, ville
where lieu.id_lieu = tc.id_lieu 
and lieu.id_ville = ville.id_ville and nom_ville = 'Toulouse'
		and type_transport ='metro'
		and annee = 2019 
		and mois >= 1 and mois <= 1
		and jour >= 11 and jour <= 11 
		and heure >= 0 and heure < 24
		and minute >= 0 and minute <= 60
group by  nom_lieu, x, y
order by nb_valid desc")


# Résultat de la requête sous la forme d’un df
df4 <- fetch(requ4, n = -1)   # extract all rows

# Symbologie couleur
library(RColorBrewer)
# Choix de la couleur de la palette
pall = brewer.pal(n= 9,name = 'YlOrRd')
# choix méthode de discrétisation + calcul des breaks
library(classInt)
ci=classIntervals(df4$nb_valid, 4, style = "jenks")

library(leaflet)
# fonction qui permet d'attribuer la couleur
pal <- colorBin(
  palette = pall,
  domain = df4$nb_valid,
  reverse = FALSE,
  bins=ci$brks
)

# on applique la couleur sur le champ dens
col=pal(df4$nb_valid)

# paramétrage de la carte


leaflet(df4) %>% 
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircles(lng = ~x, lat = ~y, weight = 1, radius = sqrt(df4$nb_valid), label = df4$nb_valid,color="#000",
             fillColor = col, opacity = 0.8, fillOpacity = 1)%>% 
  addLegend(
    title = "Nombre de validation par station",
    pal = pal, values = df4$nb_valid, opacity=0.8)
