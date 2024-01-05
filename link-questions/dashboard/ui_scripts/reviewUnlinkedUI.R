unique_ids <- dbGetQuery(
  link_conn,
  "
  SELECT distinct question_id
  FROM unlinked;
  "
)

review_unlinked <- tabPanel(
  "Review Unlinked Questions",
  sidebarPanel(
    selectInput(
      inputId = "review_question_id", label = "Question ID", choices = unique_ids
    ),
    selectInput(
      inputId = "review_proposed_link", label = "Proposed Link", choices = "None"
    ),
    actionButton(
      inputId = "review_create_link", label = "Link"
    )
  ),
  mainPanel(
    tableOutput("unlinked")
  )
)