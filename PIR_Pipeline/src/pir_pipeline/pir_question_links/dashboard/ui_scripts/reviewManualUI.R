################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Script to create UI for the Manual Link tab of the dashboard
################################################################################

# Define a tab named "Search for Questions By Keyword"
manual_review <- tabPanel(
  "Manual Links",
  fluidPage(
    fluidRow(
      column(
        selectInput(
          inputId = "manual_type", label = "Type", choices = c("linked", "unlinked")
        ),
        width = 3
      )
    ),
    fluidRow(
      tableOutput("manual_output")
    )
  )
)