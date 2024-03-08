################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Script to create home page of the dashboard
################################################################################


# home <- tabPanel(
#   "Question Link Overview",
#   fluidRow(
#     column(
#       h1(paste0("Ingestion Logs")),
#       # Use DTOutput instead of tableOutput
#       DTOutput("ingestion_logs"),
#       width = 6
#     ),
#     column(
#       width = 6,
#       h1(paste0("Question Linkage Logs")),
#       DTOutput("question_logs"),
#       fluidRow(
#         column(
#           tableOutput("home_uniq_obs"),
#           width = 3
#         ),
#         column(
#           tableOutput("home_tot_obs"),
#           width = 3
#         )
#       )
#     )
#   )
# )



home <- tabPanel(
  "Question Link Overview",
  fluidRow(
    column(
      width = 6,
      h1(paste0("Ingestion Logs")),
      # Use DTOutput instead of tableOutput
      DTOutput("ingestion_logs") # First table output
    ),
    column(
      width = 6,
      h1(paste0("Listener Logs")), # Repeat the header for the second table
      # Use DTOutput instead of tableOutput
      DTOutput("listener_logs") # Second table output
    )
  ),
  fluidRow( # Start another fluidRow layout
    column(
      width = 6,
      h1(paste0("Question Linkage Logs")), # Display a header "Question Linkage Logs"
      DTOutput("question_logs"), # Output area for displaying question linkage logs
      fluidRow(
        column(
          tableOutput("home_uniq_obs"), # Output area for displaying unique observations
          width = 3
        ),
        column(
          tableOutput("home_tot_obs"), # Output area for displaying total observations
          width = 3
        )
      )
    )
  )
)