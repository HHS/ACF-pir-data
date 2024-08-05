################################################################################
## Written by: Reggie Gilliard
## Date: 01/14/2024
## Description: Script to create UI for the Views tab of the dashboard
################################################################################

# Retrieve views from the "pir_data" database
dash_meta$view_choices <- dbGetQuery(
  conn,
  paste(
    "SHOW FULL TABLES IN", "pir_data", "WHERE table_type LIKE 'VIEW'"
  ) 
)[[1]]


# Define a tab named "Search for View by Database"
view_search <- tabPanel(
  "Search for View by Database",
  tags$head(
    tags$style(
      "
        #view_search {
          margin: 10px;
        }
      "
    )
  ),
  fluidPage(
    fluidRow(
      column(
        selectInput(
          inputId = "show_schema", label = "Database", 
          choices = dash_meta$dbnames, selected = "pir_data"
        ),
        width = 5
      ),
      column(
        selectInput(
          inputId = "show_views", label = "Select View", 
          choices = dash_meta$view_choices
        ),
        width = 5
      ),
      column(
        actionButton(
          inputId = "view_search", label = "Search"
        ),
        width = 2
      )
    ),
    fluidRow(
      tableOutput("view_output")
    )
  )
)