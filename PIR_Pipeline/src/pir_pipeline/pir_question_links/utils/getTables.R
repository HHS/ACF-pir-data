getTables <- function(question_conn, link_conn, lower_year) {
  pkgs <- c("dplyr", "purrr")
  invisible(sapply(pkgs, require, character.only = T))
  
  matching_vars <- dbGetQuery(
    link_conn,
    paste(
      "SHOW COLUMNS",
      "FROM linked",
      "WHERE Field like 'question%' OR Field IN ('section', 'year')"
    )
  )
  matching_vars <- paste(matching_vars$Field, collapse = ",")
  
  table_vars <- map(
    c("linked", "unlinked"),
    function(table) {
      dbGetQuery(
        link_conn,
        paste(
          "SHOW COLUMNS",
          "FROM", table
        )
      )
    }
  )
  
  linked_db <- dbGetQuery(
    link_conn,
    paste(
      "SELECT DISTINCT uqid,", matching_vars,
      "FROM linked"
    )
  )
  
  unlinked_db <- dbGetQuery(
    link_conn,
    paste(
      "SELECT DISTINCT *",
      "FROM unlinked"
    )
  ) %>%
    select(-proposed_link)
  
  question_frames <- map(
    c(lower_year),
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
      "unlinked_db" = unlinked_db,
      "lower_year" = question_frames[[1]], 
      # "upper_year" = question_frames[[2]],
      "question_vars" = names(question_frames[[1]]),
      "linked_vars" = table_vars[[1]]$Field,
      "unlinked_vars" = table_vars[[2]]$Field
    )
  )
}
