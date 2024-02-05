dash_meta$review_question_id_choices <- dbGetQuery(
  link_conn,
  "
  SELECT distinct question_id
  FROM unlinked;
  "
)

review_unlinked <- tabPanel(
  "Review Unlinked Questions",
  fluidPage(
    fluidRow(
      column(
        selectInput(
          inputId = "review_question_id", label = "Question ID", 
          choices = dash_meta$review_question_id_choices
        ),
        width = 5
      ),
      column(
        selectInput(
          inputId = "review_proposed_link", label = "Proposed Link", choices = "None"
        ),
        width = 5
      ),
      column(
        actionButton(
          inputId = "review_create_link", label = "Link"
        ),
        width = 2
      )
    ),
    fluidRow(
      tableOutput("unlinked")
    )
  )
)