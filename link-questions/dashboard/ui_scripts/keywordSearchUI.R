varnames <- dbGetQuery(
  link_conn,
  "
  SHOW COLUMNS 
  FROM linked
  "
)$Field

dash_meta$tables <- dbGetQuery(
  link_conn,
  "
  SHOW TABLES 
  "
)[[1]]

dash_meta$keyword_choices <- varnames[-which(varnames %in% c("uqid", "year", "question_id"))]

keyword_search <- tabPanel(
  "Search for Questions By Keyword",
  sidebarPanel(
    selectInput(
      inputId = "keyword_table", label = "Table", choices = dash_meta$tables
    ),
    selectInput(
      inputId = "keyword_column", label = "Search Column", 
      choices = dash_meta$keyword_choices
    ),
    textInput(
      inputId = "keyword_text", label = "Keyword(s)"
    ),
    checkboxInput(
      inputId = "keyword_exact", label = "Exact Match"
    ),
    actionButton(
      inputId = "keyword_search", label = "Search"
    )
  ),
  mainPanel(
    tableOutput("keyword_output")
  )
)