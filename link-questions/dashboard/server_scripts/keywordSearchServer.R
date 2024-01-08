keyword_output <- eventReactive(
  input$keyword_search,
  {
    dbGetQuery(
      link_conn,
      paste0(
        "call questionKeywordSearch(",
        "'", input$keyword_table, "',",
        "'", input$keyword_column, "',", 
        "'", input$keyword_text, "',",
        "'", as.numeric(input$keyword_exact), "'",
        ")"
      )
    ) %>%
      return()
    
    # df %>%
    #   kableExtra::kable() %>%
    #   kableExtra::kable_styling("striped") %>%
    #   return()
  }
)

output$keyword_output <- renderTable(keyword_output())