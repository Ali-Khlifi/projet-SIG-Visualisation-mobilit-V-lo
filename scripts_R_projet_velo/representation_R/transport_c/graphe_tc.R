library(RPostgreSQL)
con <- dbConnect("PostgreSQL", dbname = "projet_velos",
                 user = "projet_velos", password = "ab*rERp#Wz6m", host="193.55.175.126" ,port="2002")
requ3 <- dbSendQuery(con, "select nom_lieu, type_transport, annee, mois,jour,heure, sum(nbvalid) as sum_valid
from lieu, tc_, ville
where lieu.id_lieu = tc_.id_lieu and nom_lieu = 'Empalot'
and lieu.id_ville = ville.id_ville and nom_ville = 'Toulouse'
		and type_transport ='metro'
		and annee = 2019 
		and mois >= 1 and mois <= 1
		and jour >= 11 and jour <= 11 
		and heure >= 0 and heure < 24
		and minute >= 0 and minute <= 60
group by  nom_lieu, type_transport,annee, mois,jour,heure
")

# Résultat de la requête sous la forme d’un df
df3 <- fetch(requ3, n = -1)   # extract all rows


library(ggplot2)
graph1 <- ggplot(df3) + aes(x =heure) 
graph1 + geom_line(aes(y = sum_valid)) +
  labs(title = "", y="nombre de validation")
