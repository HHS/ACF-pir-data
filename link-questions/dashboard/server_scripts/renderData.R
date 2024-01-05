output$unlinked <- function() {
  unlinked <- dbGetQuery(
    link_conn,
    paste0(
      "call reviewUnlinked('", input$question_id, "')"
    )
  )
  
  unlinked %>%
    kableExtra::kable() %>%
    kableExtra::kable_styling("striped")
}