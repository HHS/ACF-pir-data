db_names <- dbGetQuery(
  conn,
  "
  SHOW SCHEMAS
  "
)$Database

dash_meta$views <- dbGetQuery(
  conn,
  paste(
  "show full tables in", "pir_data", "where table_type like 'VIEW'"
  )
)[[1]]



view_search <- tabPanel(
  "Search for View by Database",
  sidebarPanel(
    selectInput(
      inputId = "show_schema", label = "Database", choices = db_names, selected = "pir_data"
    ),
    selectInput(
      inputId = "show_views", label = "Select View", 
      choices = dash_meta$views
    ),
    actionButton(
      inputId = "view_search", label = "Search"
    )
  ),
  mainPanel(
    tableOutput("view_output")
  )
)