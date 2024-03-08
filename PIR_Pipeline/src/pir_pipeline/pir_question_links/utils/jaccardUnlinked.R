################################################################################
## Written by: Reggie Gilliard
## Date: 01/02/2023
## Description: Script creates Jaccard matches for unlinked questions.
################################################################################


#' Jaccard Unlinked
#' 
#' This function creates Jaccard matches for unlinked questions based on the provided ID.
#' 
#' @param conn A database connection object.
#' @param id The ID to search for in the database.
#' @return A data frame containing the Jaccard matches for unlinked questions.
#' 

jaccardUnlinked <- function(conn, id) {
  
  require(dplyr)
  # Retrieve data from unlinked table for the specified ID
  unlinked <- DBI::dbGetQuery(
    conn,
    paste(
    "SELECT *",
    "FROM unlinked",
    "WHERE question_id = ", paste0("'", id, "'")
    )
  )
  # Retrieve data from linked table
  linked <- DBI::dbGetQuery(
    conn,
    "SELECT * FROM linked"
  )
  # Prepare data from linked table with years different from the unlinked question    
  linked_yr <- linked %>%
    bind_rows(unlinked) %>%
    filter(year != unique(unlinked$year)) %>%
    mutate(
      across(c(starts_with("question")), fedmatch::clean_strings)
    ) %>%
    rename(question_id_proposed = question_id) %>%
    distinct(question_id_proposed, .keep_all = T)
  # Prepare data from unlinked table
  unlinked_yr <- unlinked %>%
    mutate(
      across(c(starts_with("question")), fedmatch::clean_strings)
    ) %>%
    rename(question_id_base = question_id)
    # Perform the match
    matches <- fedmatch::merge_plus(
      unlinked_yr, linked_yr,
      by = c("question_name", "question_text", "question_number", "section"),
      match_type = "multivar",
      unique_key_1 = "question_id_base",
      unique_key_2 = "question_id_proposed",
      suffixes = c("_base", "_proposed"),
      multivar_settings = fedmatch::build_multivar_settings(
        compare_type = c("wgt_jaccard_dist", "wgt_jaccard_dist", "wgt_jaccard_dist", "indicator"),
        wgts = c(.2, .1, .2, .5),
        top = 5
      )
    )
    
    return(matches$matches)
  
}
