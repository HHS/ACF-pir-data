output$unlinked2 <- function() {
  unlinked <- dbGetQuery(
    link_conn,
    paste0(
      "call reviewUnlinkedV('", input$review_question_id2, "')"
    )
  )
  
  unlinked %>%
    kableExtra::kable() %>%
    kableExtra::kable_styling("striped")
}

observeEvent(
  input$review_question_id2,
  {
    unlinked <- dbGetQuery(
      link_conn,
      paste0(
        "call reviewUnlinkedV('", input$review_question_id2, "')"
      )
    )
    id <- input$review_question_id2
    choices <- unique(unlinked$question_id[-which(unlinked$question_id == id)])
    updateSelectInput(
      session,
      "review_proposed_link2",
      choices = choices
    )
  }
)

observeEvent(
  input$review_create_link,
  {
    genLink(input$review_question_id2, input$review_proposed_link2, link_conn)
    updateSelectInput(
      session,
      "review_question_id2",
      choices = dash_meta$review_question_id_choices2[-which(dash_meta$review_question_id_choices2 == input$review_question_id2)],
      selected = "None"
    )
    js$refresh_page()
  }
)