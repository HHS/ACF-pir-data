output$inconsistent_link <- function() {
  
  inconsistent <- inconsistentIDMatch(link_conn, input$inconsistent_uqid)
  
  inconsistent %>%
    kableExtra::kable() %>%
    kableExtra::kable_styling("striped")
}

observeEvent(
  input$inconsistent_uqid,
  {
    inconsistent <- inconsistentIDMatch(link_conn, input$inconsistent_uqid)
    
    choices <- unique(c(inconsistent[inconsistent$name == "question_id",]))
    choices <- choices[-which(choices == "question_id")]
    updateCheckboxGroupInput(
      session,
      "inconsistent_question_id",
      choices = choices
    )
  }
)

observeEvent(
  input$inconsistent_unlink,
  {
    deleteLink(link_conn, input$inconsistent_uqid, input$inconsistent_question_id)
    updateSelectInput(
      session,
      "inconsistent_uqid",
      choices = dash_meta$inconsistent_uqid_choices,
      selected = "None"
    )
    js$refresh_page()
  }
)