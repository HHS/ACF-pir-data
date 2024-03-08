################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Script to fetch data for the view tab or the dashboard (hidden)
################################################################################

# Fetch data for the view tab of the dashboard
observe(
  {
    # Retrieve views from the selected schema
    dash_meta$views <- dbGetQuery(
      connections[[input$show_schema]],
      paste(
        "show full tables in", input$show_schema, "where table_type like 'VIEW'"
      )
    )[[1]]
    # Update choices for view selection
    choices <- dash_meta$views
    updateSelectInput(
      session,
      "show_views",
      choices = choices
    )
  }
) %>%
  bindEvent(input$show_schema)

observe(
  {
    # Retrieve data from the selected view
    view <- dbGetQuery(
      connections[[input$show_schema]],
      paste(
        "SELECT * FROM", input$show_views 
      )
    )
    # Render view output as a table
    output$view_output <- renderTable(view)
  }
) %>%
  bindEvent(input$view_search)