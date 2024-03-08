################################################################################
## Written by: Reggie Gilliard
## Date: 01/14/2024
## Description: Script to create UI for the Unlinked questions tab of the dashboard
################################################################################


# Retrieve distinct question IDs from the "unlinked" table
dash_meta$review_question_id_choices <- dbGetQuery(
  link_conn,
  "
  SELECT distinct question_id
  FROM unlinked;
  "
)

# Define a tab named "Review Unlinked Questions"
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