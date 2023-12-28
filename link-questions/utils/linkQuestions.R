linkQuestions <- function(df_list) {
  pkgs <- c("dplyr", "stringr", "assertr", "stringdist")
  invisible(sapply(pkgs, require, character.only = T))
  
  linked_db <- df_list$linked_db
  lower_year <- df_list$lower_year
  upper_year <- df_list$upper_year
  
  lower <- unique(lower_year$year)
  upper <- unique(upper_year$year)
  lower_chr <- as.character(lower)
  upper_chr <- as.character(upper)
  
  years <- c(lower, upper)
  
  if (nrow(linked_db > 0)) {
    combined <- cross_join(lower_year, linked_db) %>%
      determineLink()
    
    separated <- map(
      0:1,
      function(bool) {
        filter(combined, confirmed == bool) %>%
          select(-ends_with(".y")) %>%
          rename_with(
            ~ gsub("\\.x$", "", ., perl = T),
            ends_with(".x")
          ) %>%
          {
            if (bool == 0) {
              select(., names(lower_year))
            } else {
              .
            }
          } %>%
          return()
      }
    )
    
    unlinked <- separated[[1]]
    linked <- separated[[2]] %>%
      distinct(uqid, .keep_all = T)
    attr(linked, "db_vars") <- schema$linked
    attr(linked, "years") <- years
    
  } else {
    unlinked <- lower_year
    linked <- NULL
  }
  
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
  
    attr(combined, "years") <- years
    
    confirmed <- combined %>%
      filter(confirmed == 1)
    
    attr(confirmed, "db_vars") <- schema$linked
    
    unconfirmed <- combined %>%
      filter(confirmed == 0)
    
    attr(unconfirmed, "db_vars") <- schema$unlinked
  } else {
    confirmed <- NULL
    unconfirmed <- NULL
  }
  
  return(
    list(
      "linked" = linked, 
      "confirmed" = confirmed, 
      "unconfirmed" = unconfirmed,
      "linked_db" = linked_db
    )
  )
}
