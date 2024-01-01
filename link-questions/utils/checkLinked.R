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
  
    separated <- cross_join(lower_year, linked_db) %>%
      determineLink() %>%
      separateCombined(df_list$question_vars, "linked")
    
    unlinked <- separated$unlinked
    linked <- separated$linked %>%
      distinct(uqid, question_id, .keep_all = T) %>%
      bind_rows(linked)
    
    df_list <- append(df_list, list("linked" = linked, "unlinked" = unlinked))
    
    return(df_list)
  
  } else {
    
    df_list$unlinked <- lower_year
    return(df_list)
    
  }
}
