output$unlinked <- function() {
  unlinked <- dbGetQuery(
    link_conn,
    paste0(
      "call reviewUnlinked('", input$review_question_id, "')"
    )
  )
  
  unlinked %>%
    kableExtra::kable() %>%
    kableExtra::kable_styling("striped")
}

observeEvent(
  input$review_question_id,
  {
    unlinked <- dbGetQuery(
      link_conn,
      paste0(
        "call reviewUnlinked('", input$review_question_id, "')"
      )
    )
    id <- input$review_question_id
    choices <- unique(unlinked$question_id[-which(unlinked$question_id == id)])
    updateSelectInput(
      session,
      "review_proposed_link",
      choices = choices
    )
  }
)

observeEvent(
  input$review_create_link,
  {
    js$refresh_page()
    updateSelectInput(
      session,
      "review_question_id",
      selected = "None"
    )
  }
)