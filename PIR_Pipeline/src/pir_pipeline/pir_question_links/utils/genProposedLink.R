#' Generate a column of proposed links
#' 
#' `genProposedLink` generates a JSON column containing the
#' best unconfirmed link(s) for a given question.
#' @param df A data frame being processed by `separateCombined()`
#' @returns Input data frame with an additional column: `proposed_link`.

genProposedLink <- function(df) {

  require(dplyr)
  
  df %>%
    group_by(match_group) %>%
    # Combine all distances into a single list column
    mutate(
      across(ends_with("dist"), as.numeric),
      across(ends_with("dist"), ~ max(., na.rm = T)),
      distances = pmap(across(ends_with("dist")), list)
    ) %>%
    # Convert list column to JSON
    mutate(
      ids = c(question_id), 
      proposed_link = setNames(distances, ids),
      proposed_link = jsonlite::toJSON(proposed_link),
      year = as.numeric(year)
    ) %>%
    ungroup() %>%
    return()
}