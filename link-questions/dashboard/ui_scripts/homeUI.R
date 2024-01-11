home <- tabPanel(
  "Question Link Overview",
  fluidRow(
    column(
      width = 6, 
      "Unique Observations",
      tableOutput("home_uniq_obs")
    ),
    column(
      width = 6,
      "Total Observations",
      tableOutput("home_tot_obs")
    ),
    style = "padding: 15px"
  )
)