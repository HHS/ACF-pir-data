keyword_output <- eventReactive(
  input$keyword_search,
  {
    
    if (grepl("\"|\'", input$keyword_text)) {
      stop("Please enter a string without quotes.")
    }
    
    tryCatch(
      {
        dbGetQuery(
          link_conn,
          paste0(
            "call keywordSearch(",
            "'", input$keyword_table, "',",
            "'", input$keyword_column, "',", 
            "'", input$keyword_text, "',",
            "'", as.numeric(input$keyword_exact), "'",
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
  # df %>%
  #   kableExtra::kable() %>%
  #   kableExtra::kable_styling("striped") %>%
  #   return()
)

output$keyword_output <- renderTable(keyword_output())