observe(
  {
    dash_meta$views <- dbGetQuery(
      connections[[input$show_schema]],
      paste(
        "show full tables in", input$show_schema, "where table_type like 'VIEW'"
      )
    )[[1]]
    
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
    view <- dbGetQuery(
      connections[[input$show_schema]],
      paste(
        "SELECT * FROM", input$show_views 
      )
    )
    output$view_output <- renderTable(view)
  }
) %>%
  bindEvent(input$view_search)