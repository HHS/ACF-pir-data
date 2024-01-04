checkLinked <- function(df_list) {
  
  lower_year <- df_list$lower_year
  linked_db <- df_list$linked_db
  
  if (nrow(linked_db) > 0) {
    
    linked <- inner_join(
      lower_year, 
      linked_db %>%
        distinct(question_id, uqid),
      by = "question_id"
    )
    
    lower_year <- anti_join(
      lower_year,
      linked,
      by = "question_id"
    )
  
    if (!is.null(lower_year) && nrow(lower_year) > 0) {
      separated <- cross_join(lower_year, linked_db) %>%
        filter(year.x != year.y) %>%
        determineLink() %>%
        separateCombined(df_list$question_vars, "linked")
      
      unlinked <- separated$unlinked
      linked <- separated$linked %>%
        distinct(uqid, question_id, .keep_all = T) %>%
        bind_rows(linked)
    }
    
    df_list$linked <- linked
    if (exists("unlinked", envir = environment(), inherits = F)) {
      df_list$unlinked <- unlinked
    }
    
    return(df_list)
  
  } else {
    
    df_list$unlinked <- lower_year
    return(df_list)
    
  }
}
