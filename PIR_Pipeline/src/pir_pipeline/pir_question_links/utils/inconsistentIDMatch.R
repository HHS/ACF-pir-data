inconsistentIDMatch <- function(conn, id) {
  func_env <- environment()
  
  linked <- dbGetQuery(
    conn,
    paste(
      "SELECT DISTINCT uqid, question_id, question_name, question_text, question_number, category, section",
      "FROM linked"
    )
  )
  
  linked <- linked %>%
    filter(uqid == id) %>%
    select(-c(uqid)) %>%
    mutate(row_num = row_number()) %>%
    pivot_longer(
      -row_num
    ) %>%
    pivot_wider(
      names_from = "row_num",
      names_glue = "Question {row_num}"
    )
  
  return(linked)
}
