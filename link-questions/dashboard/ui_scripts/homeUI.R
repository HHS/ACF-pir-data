home <- tabPanel(
  "Question Link Overview",
  fluidRow(
    column(
      h1(paste0("Ingestion Logs")),
      # Use DTOutput instead of tableOutput
      DTOutput("ingestion_logs"),
      width = 6
    ),
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