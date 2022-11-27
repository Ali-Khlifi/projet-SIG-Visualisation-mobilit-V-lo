library(RPostgreSQL)
library(leaflet)
library(glue)

ui <- fluidPage(
  selectInput("ville", label = "Quelle ville ?", choices = c("Toulouse","Lyon")),
  selectInput("annee", label = "Quelle année ?", choices = c(2019,2020)),
  leafletOutput("map"))

server <- function(input, output) {
  # définition de la fonction data() qui permet de récupérer/renvoyer le df issu du résultat de la requête
  data <- reactive({
    con <- dbConnect("PostgreSQL", dbname = "projet_velos",
                     user = "projet_velos", password = "ab*rERp#Wz6m", host="193.55.175.126" ,port="2002")
    
    requ4 <- dbGetQuery(con, glue("select nom_lieu,x, y, sum(nb_valid) as nb_valid
  from lieu, tc, ville
  where lieu.id_lieu = tc.id_lieu 
  and lieu.id_ville = ville.id_ville and nom_ville = '{input$ville}'
		and type_transport ='metro'
		and annee = {input$annee}
		and mois >= 1 and mois <= 1
		and jour >= 7 and jour <= 7 
		and heure >= 0 and heure <= 24
		and minute >= 0 and minute <= 60

  group by  nom_lieu, x, y"))
    
    
    # Disconnect from the DB
    dbDisconnect(con)
    
    # Convert to data.frame
    data.frame(requ4)
  })
  
  # Render map
  output$map <- renderLeaflet({
    leaflet(data=data()) %>% 
      addProviderTiles(providers$CartoDB.Positron)%>%
      addCircles(lng = ~x, lat = ~y, weight = 1, radius = sqrt(data()$nb_valid), label = data()$nb_valid,
                 opacity = 5, fillOpacity = 1)
  })
}

shinyApp(ui = ui, server = server)
