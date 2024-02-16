dash_meta$inconsistent_id_choices <- dbGetQuery(
  link_conn,
  "
  SELECT *
  FROM imperfect_link_v
  WHERE inconsistent_question_id = 1
  "
)$uqid

inconsistent_id <- tabPanel(
  "Review Inconsistent Links",
  fluidPage(
    fluidRow(
      column(
        selectInput(
          inputId = "inconsistent_uqid", label = "Unique Question ID", 
          choices = dash_meta$inconsistent_id_choices
        ),
        width = 5
      ),
      column(
        checkboxGroupInput(
          inputId = "inconsistent_question_id", label = "IDs to Unlink", choices = "None"
        ),
        width = 5
      ),
      column(
        actionButton(
          inputId = "inconsistent_unlink", label = "Unlink"
        ),
        width = 2
      )
    ),
    fluidRow(
      tableOutput("inconsistent_link")
    )
  )
)