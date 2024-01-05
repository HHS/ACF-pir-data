#############################################
## Written by: Reggie Gilliard
## Date: 01/05/2023
## Description: Data ingestion
## ToDo: Error handling, credential management, move functions out
#############################################

rm(list = ls())
library(here)

source(here("link-questions", "dashboard", "qldSetup.R"))

ui_scripts <- list.files(here("link-questions", "dashboard", "ui_scripts"), full.names = T)
server_scripts <- list.files(here("link-questions", "dashboard", "server_scripts"), full.names = T)
invisible(sapply(ui_scripts, source))

ui <- fluidPage(
  useShinyjs(),
  extendShinyjs(text = jscode, functions = "refresh_page"),
  tabsetPanel(
    review_unlinked 
  )
)

server <- function(input, output, session) {
  for (script in server_scripts) {
    source(script, local = T)$value
  }
}

shinyApp(ui, server)