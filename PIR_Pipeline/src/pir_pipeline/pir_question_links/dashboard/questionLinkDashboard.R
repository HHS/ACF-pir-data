################################################################################
## Written by: Reggie Gilliard
## Date: 01/05/2023
## Description: Question Linking Dashboard
################################################################################


# Clear the global environment
rm(list = ls())

# Load the here package for file paths
library(here)

# Source qldSetup.R file
source(here("pir_question_links", "dashboard", "qldSetup.R"))

# Get paths to UI and server scripts
ui_scripts <- list.files(here("pir_question_links", "dashboard", "ui_scripts"), full.names = T)
server_scripts <- list.files(here("pir_question_links", "dashboard", "server_scripts"), full.names = T)

# Source UI scripts
invisible(sapply(ui_scripts, source))

# Define tab for reviewing links
question_review <- tabPanel(
  "Review Links",
  navbarPage (
    "Review Links",
    review_unlinked,
    intermittent_id,
    inconsistent_id
  )
)

# Define UI
ui <- fluidPage(
  useShinyjs(),
  extendShinyjs(text = jscode, functions = "refresh_page"),
  tabsetPanel(
    home,
    keyword_search,
    question_review
  )
)

# Define server function
server <- function(input, output, session) {
  for (script in server_scripts) {
    source(script, local = T)$value
  }
}

# Run the Shiny app
shinyApp(ui, server)

