getTables <- function(question_conn, link_conn, lower_year, upper_year) {
  pkgs <- c("dplyr", "purrr")
  invisible(sapply(pkgs, require, character.only = T))
  
  matching_vars <- dbGetQuery(
    link_conn,
    paste(
      "SHOW COLUMNS",
      "FROM linked",
      "WHERE Field like 'question%' OR Field = 'section'"
    )
  )
  
  matching_vars <- paste(matching_vars$Field, collapse = ",")
  
  linked_db <- dbGetQuery(
    link_conn,
    paste(
      "SELECT DISTINCT uqid,", matching_vars,
      "FROM linked"
    )
  )
  
  question_frames <- map(
    c(lower_year, upper_year),
    function(yr) {
      dbGetQuery(
        question_conn,
        paste(
          "SELECT *",
          "FROM question",
          "WHERE year =", yr
        )
      ) %>%
        mutate(
          across(
            starts_with("question"),
            ~ ifelse(is.na(.), "", .)
          )
        ) %>%
        return()
    }
  )
  
  return(
    list(
      "linked_db" = linked_db, 
      "lower_year" = question_frames[[1]], 
      "upper_year" = question_frames[[2]]
    )
  )
}
