checkLinked <- function(df_list) {
  
  lower_year <- df_list$lower_year
  linked_db <- df_list$linked_db
  
  if (nrow(linked_db) > 0) {
  
    separated <- cross_join(lower_year, linked_db) %>%
      determineLink() %>%
      separateCombined(df_list$question_vars, "linked")
    
    unlinked <- separated$unlinked
    linked <- separated$linked %>%
      distinct(uqid, .keep_all = T)
    
    df_list <- append(df_list, list("linked" = linked, "unlinked" = unlinked))
    
    return(df_list)
  
  } else {
    
    df_list$unlinked <- lower_year
    return(df_list)
    
  }
}
