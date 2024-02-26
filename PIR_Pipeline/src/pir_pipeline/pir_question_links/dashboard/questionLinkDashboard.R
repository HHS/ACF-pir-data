#############################################
## Written by: Reggie Gilliard
## Date: 01/05/2023
## Description: Question Linking Dashboard
#############################################

rm(list = ls())
library(here)

source(here("pir_question_links", "dashboard", "qldSetup.R"))

ui_scripts <- list.files(here("pir_question_links", "dashboard", "ui_scripts"), full.names = T)
server_scripts <- list.files(here("pir_question_links", "dashboard", "server_scripts"), full.names = T)
invisible(sapply(ui_scripts, source))

question_review <- tabPanel(
  "Review Links",
  navbarPage (
    "Review Links",
    review_unlinked,
    intermittent_id,
    inconsistent_id
  )
)

ui <- fluidPage(
  useShinyjs(),
  extendShinyjs(text = jscode, functions = "refresh_page"),
  tabsetPanel(
    home,
    keyword_search,
    question_review
  )
)

server <- function(input, output, session) {
  for (script in server_scripts) {
    source(script, local = T)$value
  }
}

shinyApp(ui, server)

