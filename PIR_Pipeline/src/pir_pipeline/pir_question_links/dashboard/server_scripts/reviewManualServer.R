################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Script to fetch data for the Manual Link tab of the dashboard
################################################################################

# Fetch data for the keyword tab of the dashboard
manual_output <- eventReactive(
  input$manual_type,
  {
    tryCatch(
      {
        # Execute keyword search query
        dbGetQuery(
          link_conn,
          paste0(
            "call reviewManual(",
            "'", input$manual_type, "'",
            ")"
          )
        ) %>%
          return()
      },
      error = function(cnd) {
        stop(cnd)
      }
    )
  }
)

# Render keyword output as a table
output$manual_output <- renderTable(manual_output())