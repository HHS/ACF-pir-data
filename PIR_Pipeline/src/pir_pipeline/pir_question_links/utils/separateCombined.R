separateCombined <- function(df, varnames, caller) {
  
  require(dplyr)
  
  func_env <- environment()
  separated <- list()
  
  if (caller == "unlinked") {
    
    combined <- df %>% 
      mutate(across(ends_with("_dist"), as.character)) %>%
      # Extract years from unlinked_db records
      tidyr::pivot_longer(c(ends_with(".y"), -year.y, ends_with("dist"))) %>%
      mutate(name = gsub("\\.y", "", name, perl = T)) %>%
      tidyr::pivot_wider(
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
        ~ stringr::str_replace_all(., c("\\.x$" = x_year)),
        everything()
      ) %>%
      genUQID() %>%
      mutate(match_group = row_number()) %>%
      tidyr::pivot_longer(
        -c("confirmed", "uqid", "match_group"),
        names_to = c(".value", "year"),
        names_pattern = "^(\\w+)(\\d{4})$"
      ) %>%
      # Subset to relevant cases
      filter(!is.na(question_id)) %>%
      mutate(
        across(c(ends_with("_dist"), year), as.numeric)
      )
    
    separated$linked <- combined %>%
      filter(confirmed == 1)
    
    separated$unlinked <- combined  %>%
      filter(confirmed == 0) %>%
      # Create proposed match column
      genProposedLink() %>%
      select(question_id, year, proposed_link)
    
  } else if (caller == "linked") {
    
    separated$linked <- filter(df, confirmed == 1) %>%
      select(-ends_with(".y")) %>%
      rename_with(
        ~ gsub("\\.x$", "", ., perl = T),
        ends_with(".x")
      )
    
    separated$unlinked <- df %>%
      filter(confirmed == 0) %>%
      mutate(match_group = row_number()) %>%
      tidyr::pivot_longer(
        c(
          ends_with(c(".x", ".y"))
        ),
        names_to = c(".value", "source"),
        names_sep = "\\."
      ) %>%
      distinct(uqid, question_id, .keep_all = T) %>%
      genProposedLink() %>%
      filter(source == "x") %>%
      select(all_of(varnames), proposed_link)
  }
  
  return(separated)
}
