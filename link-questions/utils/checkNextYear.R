checkNextYear <- function(df_list) {
  pkgs <- c("dplyr", "stringr", "assertr")
  invisible(sapply(pkgs, require, character.only = T))
  
  unlinked <- df_list$unlinked
  upper_year <- df_list$upper_year
  linked <- df_list$linked
  unlinked_db <- df_list$unlinked_db
  
  lower <- unique(unlinked$year)
  upper <- unique(upper_year$year)
  lower_chr <- as.character(lower)
  upper_chr <- as.character(upper)
  
  years <- c(lower, upper)
  
  #' Should only run if unlinked has records and the unlinked database has no
  #' records. Otherwise, all options should have been checked when checking
  #' the linked and unlinked databases
  if (nrow(unlinked) > 0 && nrow(unlinked_db) == 0) {
    combined <- cross_join(unlinked, upper_year) %>%
      determineLink() %>%
      rename_with(
        ~ str_replace_all(., c("\\.x$" = lower_chr, "\\.y$" = upper_chr)),
        everything()
      ) %>%
      assert(
        is_uniq,
        !!paste0("question_id", lower),
        error_fun = unconfirmedLink
      ) %>%
      assert(
        is_uniq,
        !!paste0("question_id", upper),
        error_fun = unconfirmedLink
      ) %>%
      select(-starts_with("year")) %>%
      genUQID() %>%
      pivot_longer(
        -c("confirmed", "uqid", ends_with("dist")),
        names_to = c(".value", "year"),
        names_pattern = "^(\\w+)(\\d{4})$"
      ) %>%
      filter(!is.na(question_id))
    
    confirmed <- combined %>%
      filter(confirmed == 1)
    
    unconfirmed <- combined %>%
      filter(confirmed == 0) %>%
      genProposedLink()
    
    if (nrow(confirmed) > 0) {
      df_list$linked <- bind_rows(confirmed, linked)
    }
    
    df_list$unlinked <- df_list$unlinked %>%
      anti_join(
        df_list$linked %>%
          select(question_id),
        by = "question_id"
      ) %>%
      left_join(
        unconfirmed,
        by = c("question_id", "year")
      )

    return(df_list)
    
  } else {
    return(df_list)
  }
}