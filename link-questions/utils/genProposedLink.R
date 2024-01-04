genProposedLink <- function(df) {
  pkgs <- c("dplyr", "jsonlite")
  invisible(sapply(pkgs, require, character.only = T))
  
  
  df %>%
    group_by(uqid) %>%
    mutate(
      across(ends_with("dist"), as.numeric),
      across(ends_with("dist"), ~ max(., na.rm = T)),
      distances = pmap(across(ends_with("dist")), list)
    ) %>%
    mutate(
      ids = c(question_id), 
      proposed_link = setNames(distances, ids),
      proposed_link = toJSON(proposed_link),
      year = as.numeric(year)
    ) %>%
    ungroup() %>%
    # select(question_id, year, proposed_link) %>%
    return()
}