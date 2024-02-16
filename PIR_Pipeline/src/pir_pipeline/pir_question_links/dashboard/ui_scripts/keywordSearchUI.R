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
  fluidPage(
    tags$head(
      tags$style(
        "
          #keyword_search {
            margin: 10px;
          }
        "
      )
    ),
    fluidRow(
      column(
        selectInput(
          inputId = "keyword_table", label = "Table", choices = dash_meta$tables
        ),
        width = 3
      ),
      column(
        selectInput(
          inputId = "keyword_column", label = "Search Column", 
          choices = dash_meta$keyword_choices
        ),
        width = 3
      ),
      column(
        textInput(
          inputId = "keyword_text", label = "Keyword(s)"
        ),
        width = 4
      ),
      column(
        checkboxInput(
          inputId = "keyword_exact", label = "Exact Match"
        ),
        width = 1,
        align = "center"
      ),
      column(
        actionButton(
          inputId = "keyword_search", label = "Search"
        ),
        width = 1
        # style = "margin:10px;"
      )
    ),
    fluidRow(
      tableOutput("keyword_output")
    )
  )
)