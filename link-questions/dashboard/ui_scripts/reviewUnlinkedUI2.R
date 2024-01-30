dash_meta$review_question_id_choices_2 <- dbGetQuery(
  link_conn,
  "
  SELECT distinct question_id
  FROM unlinked;
  "
)

review_unlinked_2 <- tabPanel(
  "Review Unlinked Questions",
  sidebarPanel(
    selectInput(
      inputId = "review_question_id2", label = "Question ID", 
      choices = dash_meta$review_question_id_choices_2
    ),
    selectInput(
      inputId = "review_proposed_link2", label = "Proposed Link", choices = "None"
    ),
    actionButton(
      inputId = "review_create_link2", label = "Link"
    )
  ),
  mainPanel(
    tableOutput("unlinked2")
  )
)