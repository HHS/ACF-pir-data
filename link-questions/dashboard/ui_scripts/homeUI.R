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
      width = 4, # Adjust the width to accommodate three columns
      h1(paste0("Ingestion Logs")),
      # Use DTOutput instead of tableOutput
      DTOutput("ingestion_logs")
    ),
    column(
      width = 4, # Adjust the width to accommodate three columns
      h1(paste0("Listener Logs"))
    ),
    column(
      width = 4, # Adjust the width to accommodate three columns
      h1(paste0("Watcher Logs")),
      # Add your content here
    )
  ),
  fluidRow(
    column(
      width = 6,
      h1(paste0("Question Linkage Logs")),
      DTOutput("question_logs"),
      fluidRow(
        column(
          tableOutput("home_uniq_obs"),
          width = 3
        ),
        column(
          tableOutput("home_tot_obs"),
          width = 3
        )
      )
    )
  )
)