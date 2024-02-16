#' Check unlinked table for question matches
#' 
#' `checkUnlinked` checks the unlinked table for question links
#' with the current year's data.
#' 
#' @param df_list List of data frames returned by `checkLinked()`
#' @returns List of data frames with updated linked/unlinked items.

checkUnlinked <- function(df_list) {
  
  require(dplyr)
  
  # Extract data
  unlinked <- df_list$unlinked
  unlinked_db <- df_list$unlinked_db
  linked <- df_list$linked
  
  # Extract the current year
  lower <- unique(df_list$lower_year$year)
  
  # If there are records in unlinked and in unlinked_db, string distance check
  # against unlinked_db
  if (!is.null(unlinked) && nrow(unlinked) > 0 && nrow(unlinked_db) > 0) {
  
    separated <- cross_join(unlinked, unlinked_db) %>%
      filter(year.x != year.y) %>%
      determineLink() %>%
      separateCombined(df_list$question_vars, "unlinked")
    
    # Bind to linked if there are newly linked records
    if (nrow(separated$linked) > 0) {
      df_list$linked <- separated$linked %>%
        bind_rows(linked)
    }
    
    # Updated unlinked list is original unlinked joined with separated$unlinked
    # Merge is done to get proposed_link
    unlinked <- df_list$unlinked %>%
      inner_join(
        separated$unlinked,
        by = c("question_id", "year")
      )
    
    if (nrow(unlinked) > 0) {
      unlinked <- unlinked %>%
        rowwise() %>%
        # Convert proposed_link to named list
        mutate(
          across(starts_with("proposed_link"), ~ list(jsonlite::fromJSON(.)))
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
      # Remove cases where proposed_link contains question_id and
      # Convert proposed_link back to JSON
      mutate(
        proposed_link = list(
          proposed_link[-which(names(proposed_link) == question_id)]
        ),
        proposed_link = jsonlite::toJSON(proposed_link)
      ) %>%
      ungroup() %>%
      select(all_of(df_list$unlinked_vars))
    
    return(df_list)
  
  } else {
    return(df_list)
  }
}