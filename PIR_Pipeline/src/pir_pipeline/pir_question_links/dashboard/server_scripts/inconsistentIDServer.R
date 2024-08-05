################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Script to fetch data for the Inconsistent links tab of the dashboard
################################################################################

# Fetch data for the Inconsistent links tab of the dashboard
output$inconsistent_link <- function() {
  # Get inconsistent IDs
  inconsistent <- inconsistentIDMatch(link_conn, input$inconsistent_uqid)
  # Render table with kableExtra package
  inconsistent %>%
    kableExtra::kable() %>%
    kableExtra::kable_styling("striped")
}

# Update checkbox group input based on selected inconsistent unique ID
observeEvent(
  input$inconsistent_uqid,
  {
    # Get inconsistent IDs
    inconsistent <- inconsistentIDMatch(link_conn, input$inconsistent_uqid)
    
    # Filter unique IDs for questions
    choices <- unique(c(inconsistent[inconsistent$name == "question_id",]))
    choices <- choices[-which(choices == "question_id")]
    # Update checkbox group input
    updateCheckboxGroupInput(
      session,
      "inconsistent_question_id",
      choices = choices
    )
  }
)

# Event handler for unlinking inconsistent IDs
observeEvent(
  input$inconsistent_unlink,
  {
    # Delete link
    deleteLink(link_conn, input$inconsistent_uqid, input$inconsistent_question_id)
    
    shiny::showModal(
      shiny::modalDialog(
        paste0(
          "Removed link between ", input$inconsistent_uqid, " and ", input$inconsistent_question_id, "!"
        ),
        easyClose = TRUE
      )
    )
    
    # Update select input and reset to default
    updateSelectInput(
      session,
      "inconsistent_uqid",
      choices = dash_meta$inconsistent_uqid_choices,
      selected = "None"
    )
  }
)