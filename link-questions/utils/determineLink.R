#' Determine whether two questions are considered linked
#' 
#' `determineLink` determines whether two questions are considered
#' linked by measuring the edit distance between their question numbers,
#' names, texts, and sections. 
#' 
#' The following logic is used to determine whether two questions link:
#' 1) The questions are in the same section.
#' 2) Two of the following metrics are identical for the questions: number,
#' name, text.
#' 3) The question to be linked has only one match or if there are multiple
#' matches, they all meet the criteria above (as in the case where a question
#' number changes across years, but question name and text remain the same.)
#' @param df A cross joined question data frame.
#' @returns A data frame with confirmed question links.

determineLink <- function(df) {
  pkgs <- c("stringdist", "dplyr", "assertr")
  invisible(sapply(pkgs, require, character.only = T))
  
  df <- df %>%
    # Calculate string distances and sum
    mutate(
      question_number_dist = stringdist(question_number.x, question_number.y),
      question_name_dist = stringdist(question_name.x, question_name.y),
      question_text_dist = stringdist(question_text.x, question_text.y),
      section_dist = stringdist(section.x, section.y)
    ) %>%
    mutate(
      dist_sum = rowSums(.[grepl("_dist", names(.), perl = T)])
    ) %>%
    group_by(question_number.x, question_name.x, question_text.x) %>%
    mutate(
      min_dist_sum = min(dist_sum)
    )
  
  df %>%
    # Create indicator for confirmed matches
    mutate(
      confirmed = case_when(
        section_dist != 0 ~ 0,
        dist_sum == 0 ~ 1,
        (question_name_dist == 0 & question_text_dist == 0) |
          (question_name_dist == 0 & question_number_dist == 0) |
          (question_text_dist == 0 & question_number_dist == 0) ~ 1,
        TRUE ~ 0
      )
    ) %>%
    # Keep record(s) with min sum of string distance
    filter(
      dist_sum == min_dist_sum | confirmed == 1
    ) %>%
    ungroup() %>%
    group_by(question_id.y) %>%
    mutate(id_y_appearances = n()) %>%
    ungroup() %>%
    group_by(question_id.x) %>%
    # Update confirmed matches
    mutate(
      index = row_number(),
      id_x_appearances = n(),
      confirmed_sum = sum(confirmed),
      confirmed = case_when(
        id_y_appearances > 1 & confirmed_sum == 1 & confirmed == 1 ~ 1,
        id_x_appearances == confirmed_sum & index == 1 ~ 1,
        id_y_appearances > 1 ~ 0,
        TRUE ~ confirmed
      )
    ) %>%
    ungroup() %>%
    assert(not_na, question_id.x) %>%
    # Confirm that newly matched records are only confirmed once
    pipeExpr(
      . %>%
        filter(confirmed == 1) %>%
        assert(is_uniq, question_id.x)
    ) %>%
    # Return confirmed records
    {
      tryCatch(
        {
          group_by(., question_id.x) %>%
            mutate(
              max_confirmed = max(confirmed)
            ) %>%
            ungroup() %>%
            filter(
              !(confirmed == 0 & max_confirmed == 1),
              !(confirmed_sum == max_confirmed & index != 1 & confirmed_sum != 1)
            ) %>%
            return()
        },
        error = function(cnd) {
          return(.)
        }
      )
    } %>%
    return()
  
}
