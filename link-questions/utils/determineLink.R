determineLink <- function(df) {
  pkgs <- c("stringdist", "dplyr", "assertr")
  invisible(sapply(pkgs, require, character.only = T))
  
  df %>%
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
    ) %>%
    filter(
      dist_sum == min(dist_sum)
    ) %>%
    ungroup() %>%
    group_by(question_id.y) %>%
    mutate(id_y_appearances = n()) %>%
    ungroup() %>%
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
    group_by(question_id.x) %>%
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
    pipeExpr(
      . %>%
        filter(confirmed == 1) %>%
        assert(is_uniq, question_id.x)
    ) %>%
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
              !(confirmed_sum == max_confirmed & index != 1)
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
