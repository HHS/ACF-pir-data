checkNextYear <- function(df_list) {
  unlinked <- df_list$unlinked
  upper_year <- df_list$upper_year
  confirmed <- df_list$confirmed
  unconfirmed <- df_list$unconfirmed
  
  lower <- unique(unlinked$year)
  upper <- unique(upper_year$year)
  lower_chr <- as.character(lower)
  upper_chr <- as.character(upper)
  
  years <- c(lower, upper)
  
  if (nrow(unlinked) > 0) {
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
      )
    
    confirmed <- combined %>%
      filter(confirmed == 1) %>%
      bind_rows(confirmed)
    
    unconfirmed <- combined %>%
      filter(confirmed == 0) %>%
      bind_rows(unconfirmed)
    
    df_list$confirmed <- confirmed
    df_list$unconfirmed <- unconfirmed
    
  } else {
    return()
  }
  
}