separateCombined <- function(df, varnames, caller) {
  
  pkgs <- c("dplyr", "stringr", "assertr")
  invisible(sapply(pkgs, require, character.only = T))
  
  func_env <- environment()
  separated <- list()
  
  if (caller == "unlinked") {
    
    combined <- df %>%
      # Extract years from unlinked_db records
      pivot_longer(c(ends_with(".y"), -year.y)) %>%
      mutate(name = gsub("\\.y", "", name, perl = T)) %>%
      pivot_wider(
        id_cols = c(ends_with(".x"), confirmed),
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
      genUQID() %>%
      pivot_longer(
        -confirmed,
        names_to = c(".value", "year"),
        names_pattern = "^(\\w+)(\\d{4})$"
      ) %>%
      # Subset to relevant cases
      filter(!is.na(question_id))
    
    separated$linked <- combined %>%
      filter(confirmed == 1)
    
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
