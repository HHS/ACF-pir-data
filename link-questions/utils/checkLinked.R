#' Check linked table for question matches
#' 
#' `checkLinked` checks the linked table for question links
#' with the current year's data.
#' 
#' @param df_list List of data frames returned by `getTables()`
#' @returns List of data frames including linked and unlinked records.

checkLinked <- function(df_list) {
  
  pkgs <- c("dplyr", "stringr", "assertr")
  invisible(sapply(pkgs, require, character.only = T))
  
  # Extract data of interest
  lower_year <- df_list$lower_year
  linked_db <- df_list$linked_db
  unlinked_db <- df_list$unlinked_db
  func_env <- environment()
  
  # Check for data in linked_db
  if (nrow(linked_db) > 0) {
    
    # Attempt to merge directly to linked
    linked <- inner_join(
      lower_year, 
      linked_db %>%
        distinct(question_id, uqid),
      by = "question_id"
    )
    
    # Filter out any records that merged directly from the current year
    lower_year <- anti_join(
      lower_year,
      linked,
      by = "question_id"
    )
    
    # Attempt to merge directly to unlinked
    unlinked_match <- inner_join(
      lower_year,
      unlinked_db,
      by = "question_id"
    )
    
    # If successful bind these matched records to linked
    if (nrow(unlinked_match) > 0) {
      
      linked <- unlinked_match %>%
        # Cannot match to same year
        filter(year.x != year.y) %>%
        # Pivot to get columns with matches by year
        pivot_longer(c(ends_with(".y"), -year.y)) %>%
        mutate(name = gsub("\\.y", "", name, perl = T)) %>%
        pivot_wider(
          id_cols = c(ends_with(".x"), question_id),
          names_from = c(name, year.y),
          values_from = value,
          names_glue = "{name}{year.y}"
        ) %>%
        # Extract years from the unlinked records
        pipeExpr(
          assign("x_year", as.character(unique(.[["year.x"]])), envir = func_env)
        ) %>%
        select(-year.x) %>%
        rename_with(
          ~ str_replace_all(., c("\\.x$" = x_year)),
          everything()
        ) %>%
        # Generate unique question id
        genUQID() %>%
        # Pivot from one row per uqid to one row per uqid/year
        pivot_longer(
          -c("uqid", "question_id"),
          names_to = c(".value", "year"),
          names_pattern = "^(\\w+)(\\d{4})$"
        ) %>%
        select(all_of(df_list$linked_vars)) %>%
        mutate(year = as.numeric(year)) %>%
        bind_rows(linked)
      
        # Update current year, removing linked records
        lower_year <- anti_join(
          lower_year,
          linked,
          by = "question_id"
        )
        
    }
      
  
    # If there are still records in the current year, string distance check
    # against the linked database
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
  
  # If no records in the current year, the list of unlinked records is equal
  # to the current year's data
  } else {
    
    df_list$unlinked <- lower_year
    return(df_list)
    
  }
}
