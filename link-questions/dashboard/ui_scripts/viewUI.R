dash_meta$view_choices <- dbGetQuery(
  conn,
  paste(
  "SHOW FULL TABLES IN", "pir_data", "WHERE table_type LIKE 'VIEW'"
  )
)[[1]]



view_search <- tabPanel(
  "Search for View by Database",
  sidebarPanel(
    selectInput(
      inputId = "show_schema", label = "Database", 
      choices = dash_meta$dbnames, selected = "pir_data"
    ),
    selectInput(
      inputId = "show_views", label = "Select View", 
      choices = dash_meta$view_choices
    ),
    actionButton(
      inputId = "view_search", label = "Search"
    )
  ),
  mainPanel(
    tableOutput("view_output")
  )
)