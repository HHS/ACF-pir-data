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
        width = 3
      ),
      column(
        selectInput(
          inputId = "review_algorithm", label = "Algorithm",
          choices = c("Base", "Jaccard"), selected = "Base"
        ),
        width = 3
      ),
      column(
        selectInput(
          inputId = "review_proposed_link", label = "Proposed Link", choices = "None"
        ),
        width = 3
      ),
      column(
        actionButton(
          inputId = "review_create_link", label = "Link"
        ),
        width = 3
      )
    ),
    fluidRow(
      tableOutput("unlinked")
    )
  )
)