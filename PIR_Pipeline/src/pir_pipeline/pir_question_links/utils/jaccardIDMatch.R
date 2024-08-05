################################################################################
## Written by: Reggie Gilliard
## Date: 01/02/2023
## Description: Create a Jaccard ID Match.
################################################################################


#' Jaccard ID Match
#' 
#' @param conn A database connection object.
#' @param id The ID to search for in the database.
#' @param type The type of match to perform ("unlinked" or "intermittent").
#' @return A data frame containing the Jaccard ID matches.
#' 

jaccardIDMatch <- function(conn, id, type) {
  
  require(dplyr)
  
  func_env <- environment()
  # Retrieve data from linked table
  linked <- DBI::dbGetQuery(
    conn,
    paste(
      "SELECT *",
      "FROM linked"
    )
  )
  # Retrieve data from unlinked table
  unlinked <- DBI::dbGetQuery(
    conn,
    "
    SELECT *
    FROM unlinked
    "
  )
  # Determine the sample based on the type
  if (type == "unlinked") {
    
    sample <- unlinked %>%
      filter(question_id == id)
    
  } else if (type == "intermittent") {
    
    sample <- linked %>%
      filter(uqid == id)
    
  }
  # Prepare the sample data
  sample <- sample %>%
    pipeExpr(assign("sample_years", unique(.$year), func_env)) %>%
    mutate(
      across(
        c("question_name", "question_text", "question_number"), 
        fedmatch::clean_strings
      )
    ) %>%
    distinct(question_id, .keep_all = T) %>%
    select(-c(category)) %>%
    rename(question_id_base = question_id)
  
  pool <- linked %>%
    filter(uqid != id & year %notin% sample_years) %>%
    select(starts_with("question"), section, year) %>%
    rbind(
      unlinked %>%
        filter(
          year %notin% sample_years,
          question_id != id
        ) %>%
        select(starts_with("question"), section, year)
    ) %>%
    mutate(across(c("question_name", "question_text", "question_number"), fedmatch::clean_strings)) %>%
    distinct(question_id, .keep_all = T) %>%
    rename(question_id_proposed = question_id)
  # Perform the match
  match <- fedmatch::merge_plus(
    sample, pool,
    by = c("question_name", "question_text", "question_number", "section"),
    match_type = "multivar",
    unique_key_1 = "question_id_base",
    unique_key_2 = "question_id_proposed",
    suffixes = c("_base", "_proposed"),
    multivar_settings = fedmatch::build_multivar_settings(
      compare_type = c("wgt_jaccard_dist", "wgt_jaccard_dist", "wgt_jaccard_dist", "indicator"),
      wgts = c(.15, .15, .15, .55)
    )
  )
  
  return(match)
}