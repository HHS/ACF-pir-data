jaccardUnlinked <- function(conn, id) {
  
  require(dplyr)
  
  unlinked <- DBI::dbGetQuery(
    conn,
    paste(
    "SELECT *",
    "FROM unlinked",
    "WHERE question_id = ", paste0("'", id, "'")
    )
  )
  
  linked <- DBI::dbGetQuery(
    conn,
    "SELECT * FROM linked"
  )
      
  linked_yr <- linked %>%
    bind_rows(unlinked) %>%
    filter(year != unique(unlinked$year)) %>%
    mutate(
      across(starts_with("question"), clean_strings)
    ) %>%
    rename(question_id_proposed = question_id) %>%
    distinct(question_id_proposed, .keep_all = T)
  
  unlinked_yr <- unlinked %>%
    mutate(
      across(c(starts_with("question")), fedmatch::clean_strings)
    ) %>%
    rename(question_id_base = question_id)
  
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
