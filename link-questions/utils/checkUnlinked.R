checkUnlinked <- function(df_list) {
  unlinked <- df_list$unlinked
  unlinked_db <- df_list$unlinked_db
  linked <- df_list$linked
  
  if (nrow(unlinked) > 0 && nrow(unlinked_db) > 0) {
  
    separated <- cross_join(unlinked, unlinked_db) %>%
      determineLink() %>%
      separateCombined(df_list$question_vars, "unlinked")
    
    df_list$confirmed <- separated$confirmed
    df_list$unconfirmed <- separated$unconfirmed
    df_list$remove_unlinked <- separated$remove_unlinked
    
    return(df_list)
  
  } else {
    return(df_list)
  }
}

temp2 <- checkUnlinked(temp)
  
