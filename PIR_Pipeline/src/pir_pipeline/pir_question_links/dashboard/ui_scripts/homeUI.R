################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Script to create home page of the dashboard
################################################################################

home <- tabPanel(
  "Question Link Overview",
  fluidRow(
    column(
      width = 12,
      h1(paste0("Ingestion Logs")),
      # Use DTOutput instead of tableOutput
      DTOutput("ingestion_logs") # First table output
    )
  ),
  fluidRow(
    column(
      width = 12,
      h1(paste0("Listener Logs")), # Repeat the header for the second table
      # Use DTOutput instead of tableOutput
      DTOutput("listener_logs") # Second table output
    )
  ),
  fluidRow( # Start another fluidRow layout
    column(
      width = 12,
      h1(paste0("Question Linkage Logs")), # Display a header "Question Linkage Logs"
      DTOutput("question_logs"), # Output area for displaying question linkage logs,
    )
  ),
  fluidRow(
    h1("Unique and Total Question Counts"),
    column(
      DTOutput("home_uniq_obs"), # Output area for displaying unique observations
      width = 6
    ),
    column(
      DTOutput("home_tot_obs"), # Output area for displaying total observations
      width = 6
    )
  )
)