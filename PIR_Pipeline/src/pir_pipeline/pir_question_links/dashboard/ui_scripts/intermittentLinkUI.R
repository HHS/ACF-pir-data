################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Script to create Intermittent links tab of the dashboard
################################################################################


# Retrieve intermittent unique question ID choices from the database
dash_meta$intermittent_uqid_choices <- dbGetQuery(
  link_conn,
  "
  SELECT distinct uqid
  FROM imperfect_link_v
  WHERE intermittent_link = 1
  "
)$uqid
# Define a tab named "Review Intermittent Links"
intermittent_id <- tabPanel(
  "Review Intermittent Links",
  fluidPage(
    fluidRow(
      column(
        selectInput(
          inputId = "intermittent_uqid", label = "Unique Question ID", 
          choices = dash_meta$intermittent_uqid_choices
        ),
        width = 5
      ),
      column(
        selectInput(
          inputId = "intermittent_proposed_link", label = "Proposed Link", choices = "None"
        ),
        width = 5
      ),
      column(
        actionButton(
          inputId = "intermittent_create_link", label = "Link"
        ),
        width = 2
      )
    ),
    fluidRow(
      tableOutput("intermittent_link")
    )
  )
)