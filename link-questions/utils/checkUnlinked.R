checkUnlinked <- function(df_list) {
  unlinked <- df_list$unlinked
  unlinked_db <- df_list$unlinked_db
  linked <- df_list$linked
  
  lower <- unique(df_list$lower_year$year)
  
  if (!is.null(unlinked) && nrow(unlinked) > 0 && nrow(unlinked_db) > 0) {
  
    separated <- cross_join(unlinked, unlinked_db) %>%
      determineLink() %>%
      separateCombined(df_list$question_vars, "unlinked")
    
    if (nrow(separated$linked) > 0) {
      df_list$linked <- separated$linked %>%
        bind_rows(linked)
    }
    
    df_list$unlinked <- df_list$unlinked %>%
      anti_join(
        df_list$linked %>%
          select(question_id),
        by = "question_id"
      ) %>%
      left_join(
        separated$unlinked,
        by = c("question_id", "year")
      )
    
    return(df_list)
  
  } else {
    return(df_list)
  }
}