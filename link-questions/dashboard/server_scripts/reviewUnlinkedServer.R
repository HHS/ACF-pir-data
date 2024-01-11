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
    genLink(input$review_question_id, input$review_proposed_link, link_conn)
    updateSelectInput(
      session,
      "review_question_id",
      choices = dash_meta$review_question_id_choices[-which(dash_meta$review_question_id_choices == input$review_question_id)],
      selected = "None"
    )
    js$refresh_page()
  }
)