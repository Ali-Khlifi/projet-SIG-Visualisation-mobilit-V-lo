
library(RPostgreSQL)
library(RColorBrewer)
library(classInt)
library(leaflet)
library(glue)

ui <- fluidPage(sidebarLayout(
  sidebarPanel(
  selectInput("ville", label = "Quelle ville ?", choices = c("Toulouse","Lyon")),
  selectInput("tc", label = "Quelle type de transport en commun ?", choices = c("metro","autre")),
  selectInput("annee", label = "Quelle année ?", choices = c(2019,2020)),
  sliderInput("mois", label= "Intervalle pour le mois", min=1, max=12, value=c(1,1)),
  sliderInput("jour", label= "Intervalle pour le jour", min=1, max=31, value=c(11,11)),
  sliderInput("heure", label= "Intervalle pour l'heure", min=0, max=23, value=c(0,24)),
  sliderInput("minute", label= "Intervalle pour les minutes", min=0, max=60, value=c(0,60))),
  mainPanel(
  leafletOutput("map", height = 600))))

server <- function(input, output) {
  # définition de la fonction data() qui permet de récupérer/renvoyer le df issu du résultat de la requête
  data <- reactive({
    con <- dbConnect("PostgreSQL", dbname = "projet_velos",
                       user = "projet_velos", password = "ab*rERp#Wz6m", host="193.55.175.126" ,port="2002")

  requ4 <- dbGetQuery(con, glue("select nom_lieu,x, y, sum(nb_valid) as nb_valid
  from lieu, tc, ville
  where lieu.id_lieu = tc.id_lieu 
  and lieu.id_ville = ville.id_ville and nom_ville = '{input$ville}'
		and type_transport ='{input$tc}'
		and annee = {input$annee}
		and mois >= {input$mois[1]} and mois <= {input$mois[2]}
		and jour >= {input$jour[1]} and jour <= {input$jour[2]}
		and heure >= {input$heure[1]} and heure <= {input$heure[2]}
		and minute >= {input$minute[1]} and minute <= {input$minute[2]}

  group by  nom_lieu, x, y
  order by nb_valid desc"))
  
  
  # Disconnect from the DB
  dbDisconnect(con)
  
  # Convert to data.frame
  data.frame(requ4)
  
})

  pal <- reactive({

  # fonction qui permet d'attribuer la couleur
  colorBin(
    palette = brewer.pal(n= 9,name = 'YlOrRd'),
    domain = data()$nb_valid,
    reverse = FALSE,
    bins=classIntervals(data()$nb_valid, 4, style = "jenks")$brks
  )
  })
  
  col <- reactive({
    pal_ <- colorBin(
      palette = brewer.pal(n= 9,name = 'YlOrRd'),
      domain = data()$nb_valid,
      reverse = FALSE,
      bins=classIntervals(data()$nb_valid, 4, style = "jenks")$brks
    )
    pal_(data()$nb_valid)
  })
  
  # Render map
  output$map <- renderLeaflet({
leaflet(data=data()) %>% 
  addProviderTiles(providers$CartoDB.Positron)%>%
  addCircles(lng = ~x, lat = ~y, weight = 1, radius = sqrt(data()$nb_valid), label = data()$nom_lieu, color="#000",
             fillColor = col(),opacity = 0.8, fillOpacity = 1) %>% 
      addLegend(
        title = "Nombre de validation par station",
        pal = pal(), values = data()$nb_valid, opacity=0.8)
})
}

shinyApp(ui = ui, server = server)

