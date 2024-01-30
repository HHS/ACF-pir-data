#############################################
## Written by: Reggie Gilliard
## Date: 01/05/2023
## Description: Question Linking Dashboard
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
    home,
    keyword_search,
    review_unlinked,
    review_unlinked_2,
    view_search
  )
)

server <- function(input, output, session) {
  for (script in server_scripts) {
    source(script, local = T)$value
  }
}

shinyApp(ui, server)

