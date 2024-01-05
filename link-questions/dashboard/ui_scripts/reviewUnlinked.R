unique_ids <- dbGetQuery(
  link_conn,
  "
  SELECT distinct question_id
  FROM unlinked;
  "
)

link_tab <- tabPanel(
  "Review Unlinked Questions",
  sidebarPanel(
    selectInput(
      inputId = "question_id", label = "Question ID", choices = unique_ids
    )
  ),
  mainPanel(
    tableOutput("unlinked")
  )
)