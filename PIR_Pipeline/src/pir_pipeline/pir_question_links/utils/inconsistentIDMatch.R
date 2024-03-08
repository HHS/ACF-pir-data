################################################################################
## Written by: Reggie Gilliard
## Date: 01/02/2023
## Description: Script to retrieve inconsistent ID matches.
################################################################################


#' Inconsistent ID Match
#' 
#' This function retrieves inconsistent ID matches from the provided connection for a specific ID.
#' 
#' @param conn A database connection object.
#' @param id The ID to search for in the database.
#' @return A data frame containing the inconsistent ID matches.
#' 

inconsistentIDMatch <- function(conn, id) {
  require(dplyr)
  func_env <- environment()
  
  # Retrieve distinct data from linked table based on provided ID
  linked <- DBI::dbGetQuery(
    conn,
    paste(
      "SELECT DISTINCT uqid, cast(year as char) as year, question_id, question_name, question_text, question_number, category, section",
      "FROM linked"
    )
  )
  
  # Filter the data to include only rows with the specified ID
  linked <- linked %>%
    filter(uqid == id) %>%
    select(-c(uqid)) %>%
    mutate(row_num = row_number()) %>%
    tidyr::pivot_longer(
      -row_num
    ) %>%
    tidyr::pivot_wider(
      names_from = "row_num",
      names_glue = "Question {row_num}"
    )
  
  return(linked)
}
