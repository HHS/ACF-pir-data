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
if (unlinked_count > 0) {
  tabs <- tabsetPanel(
    id = "tabs",
    home,
    keyword_search,
    question_review,
    manual_review,
    tabPanel("Shutdown", value = "close"),
  )
} else {
  tabs <- tabsetPanel(
    id = "tabs",
    home,
    keyword_search,
    manual_review,
    tabPanel("Shutdown", value = "close"),
  )
}
ui <- fluidPage(
  useShinyjs(),
  extendShinyjs(text = js_refresh, functions = "refresh_page"),
  extendShinyjs(text = js_close, functions = "closeWindow"),
  tabs
)

# Define server function
server <- function(input, output, session) {
  for (script in server_scripts) {
    source(script, local = T)$value
  }
  observeEvent(input$tabs, {
    if (input$tabs == "close") {
      js$closeWindow()
      map(connections, DBI::dbDisconnect)
      stopApp()
    }
  })
}

# Run the Shiny app
shinyApp(ui, server)

