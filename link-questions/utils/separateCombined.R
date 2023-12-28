separateCombined <- function(df, varnames, caller) {
  
  func_env <- environment()
  separated <- list()
  
  if (caller == "unlinked") {
    remove_unlinked <- df %>%
      filter(confirmed == 1)
    
    if (nrow(remove_unlinked > 0)) {
      remove_unlinked <- remove_unlinked %>%
        select(-ends_with(".x")) %>%
        rename_with(
          ~ gsub("\\.y", "", ., perl = T),
          ends_with(".y")
        ) %>%
        select(all_of(varnames))
    } else {
      remove_unlinked <- NULL
    }
    
    combined <- df %>%
      pipeExpr(
        assign("x_year", as.character(unique(.[["year.x"]])), envir = func_env)
      ) %>%
        pipeExpr(
          assign("y_year", as.character(unique(.[["year.y"]])), envir = func_env)
        ) %>%
        rename_with(
          ~ str_replace_all(., c("\\.x$" = x_year, "\\.y$" = y_year)),
          everything()
        ) %>%
        select(matches("\\d+$"), confirmed)
    
    separated$confirmed <- combined %>%
      filter(confirmed == 1)
    
    separated$unconfirmed <- combined %>%
      filter(confirmed == 0)
    
    separated$remove_unlinked <- remove_unlinked
    
  } else if (caller == "linked") {
    
    separated <- map(
      0:1,
      function(bool) {
        filter(df, confirmed == bool) %>%
          select(-ends_with(".y")) %>%
          rename_with(
            ~ gsub("\\.x$", "", ., perl = T),
            ends_with(".x")
          ) %>%
          {
            if (bool == 0) {
              select(., all_of(varnames))
            } else {
              .
            }
          } %>%
          return()
      }
    )
    
    separated$linked <- separated[[2]]
    separated$unlinked <- separated[[1]]
  }
  
  return(separated)
}
