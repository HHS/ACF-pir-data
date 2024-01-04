checkUnlinked <- function(df_list) {
  unlinked <- df_list$unlinked
  unlinked_db <- df_list$unlinked_db
  linked <- df_list$linked
  
  lower <- unique(df_list$lower_year$year)
  
  if (!is.null(unlinked) && nrow(unlinked) > 0 && nrow(unlinked_db) > 0) {
  
    separated <- cross_join(unlinked, unlinked_db) %>%
      filter(year.x != year.y) %>%
      determineLink() %>%
      separateCombined(df_list$question_vars, "unlinked")
    
    if (nrow(separated$linked) > 0) {
      df_list$linked <- separated$linked %>%
        bind_rows(linked)
    }
    
    unlinked <- df_list$unlinked %>%
      anti_join(
        df_list$linked %>%
          select(question_id),
        by = "question_id"
      ) %>%
      left_join(
        separated$unlinked,
        by = c("question_id", "year")
      )
    
    if (nrow(unlinked) > 0) {
      unlinked <- unlinked %>%
        # Merge proposed links
        rowwise() %>%
        mutate(
          across(starts_with("proposed_link"), ~ list(fromJSON(.)))
        ) 
    }
    
    # Combine proposed_link lists if there are multiple
    df_list$unlinked <- unlinked %>%
      {
        if (!is.null(.$proposed_link.x)) {
          mutate(
            ., 
            proposed_link = list(append(proposed_link.x, proposed_link.y))
          )
        } else {
          .
        }
      } %>%
      mutate(
        proposed_link = list(
          proposed_link[-which(names(proposed_link) == question_id)]
        ),
        proposed_link = toJSON(proposed_link)
      ) %>%
      ungroup() %>%
      select(all_of(df_list$unlinked_vars))
    
    return(df_list)
  
  } else {
    return(df_list)
  }
}