################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Script to fetch data for the keyword tab of the dashboard
################################################################################

# Fetch data for the keyword tab of the dashboard
keyword_output <- eventReactive(
  input$keyword_search,
  {
    # Check for quotes in the input keyword text
    if (grepl("\"|\'", input$keyword_text)) {
      stop("Please enter a string without quotes.")
    }
    
    tryCatch(
      {
        # Execute keyword search query
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
)

observeEvent(
  input$keyword_table,
  {
    varnames <- dbGetQuery(
      link_conn,
      paste(
        "SHOW COLUMNS",
        "FROM", input$keyword_table
      )
    )$Field

    choices <- varnames
    
    # Update the keyword text input placeholder
    updateSelectInput(
      session,
      "keyword_column",
      choices = choices
    )
  }
)

# Render keyword output as a table
output$keyword_output <- renderTable(keyword_output())