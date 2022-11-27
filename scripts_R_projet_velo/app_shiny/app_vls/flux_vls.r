library(sf)
library(RPostgreSQL)
library(RColorBrewer)
library(classInt)
library(leaflet)
library(glue)

ui <- fluidPage(sidebarLayout(
  sidebarPanel(
  selectInput("ville", label = "Quelle ville ?", choices = c("Lyon","Toulouse")),
  selectInput("annee", label = "Quelle annne ?", choices = c(2019,2020)),
  textInput("station", label= "Quelle station ?", value = 'Bourse Du Travail'),
  sliderInput("filtre", label= "Afficher des trajets avec une frequentation d'au moins :", min=1, max=20, value=1),
  sliderInput("mois", label= "Intervalle pour le mois", min=1, max=12, value=c(1,1)),
  sliderInput("jour", label= "Intervalle pour le jour", min=1, max=31, value=c(1,1)),
  sliderInput("heure", label= "Intervalle pour l'heure", min=0, max=23, value=c(0,23)),
  sliderInput("minute", label= "Intervalle pour les minutes", min=0, max=60, value=c(0,60))),
  mainPanel(
  leafletOutput("map", height = 600))))

server <- function(input, output) {
  # définition de la fonction data() qui permet de récupérer/renvoyer le df issu du résultat de la requête
  data <- reactive({
    con <- dbConnect("PostgreSQL", dbname = "projet_velos",
                       user = "projet_velos", password = "ab*rERp#Wz6m", host="193.55.175.126" ,port="2002")

  requ4 <- read_sf(con, query= glue ("select trajet, st_makeline(ls.geom, lr.geom) as geometry, nb_trajet, lr.x as x_r,lr.y as y_r
from
(select id_lieu_s,id_lieu_r, trajet, count (trajet) as nb_trajet 
from velo, lieu, ville 
where nom_ville = '{input$ville}' and ville.id_ville = lieu.id_ville
	and nom_lieu = '{input$station}' and velo.id_lieu_s = lieu.id_lieu
		and annee_s = {input$annee}
		and mois_s >= {input$mois[1]} and mois_s <= {input$mois[2]}
		and jour_s >= {input$jour[1]} and jour_s <= {input$jour[2]}
		and heure_s >= {input$heure[1]} and heure_s <= {input$heure[2]}
		and minute_s >= {input$minute[1]} and minute_s <= {input$minute[2]}
 group by trajet,id_lieu_s,id_lieu_r) as t
inner join lieu as ls on t.id_lieu_s = ls.id_lieu
inner join lieu as lr on t.id_lieu_r = lr.id_lieu
where nb_trajet >= 1
"))
return (requ4)
  
  # Disconnect from the DB
  dbDisconnect(con)
  
  # Convert to data.frame
  #data.frame(requ4)
})

  
  # Render map
  output$map <- renderLeaflet({
    map<- leaflet(data()) %>% 
      addProviderTiles(providers$CartoDB.Positron)%>%
      addPolylines (data = data()$geometry, weight = data()$nb_trajet*2,
                    opacity = 1)
      addCircles(map= map, lng = ~data()$x_r, lat = ~data()$y_r, radius= data()$nb_trajet*50, weight = 1)
})}

shinyApp(ui = ui, server = server)
