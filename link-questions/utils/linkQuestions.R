linkQuestions <- function(x, y) {
  require(dplyr)
  require(stringr)
  require(assertr)
  
  unconfirmed <- function(list_of_errors, data) {
    error_df <- list_of_errors[[1]]$error_df
    column <- unique(error_df$column)
    values <- unique(error_df$value)
    data %>%
      mutate(
        confirmed = ifelse(
          !!sym(paste(column)) %in% values,
          0,
          confirmed
        )
      ) %>%
      return()
  }
  
  x_year <- unique(x$year)
  y_year <- unique(y$year)
  x_year_chr <- as.character(x_year)
  y_year_chr <- as.character(y_year)
  
  years <- c(x_year, y_year)
  
  combined <- cross_join(x, y) %>%
    mutate(
      question_number_dist = stringdist::stringdist(question_number.x, question_number.y),
      question_name_dist = stringdist::stringdist(question_name.x, question_name.y),
      question_text_dist = stringdist::stringdist(question_text.x, question_text.y),
      section_dist = stringdist::stringdist(section.x, section.y)
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
    mutate(num_matches = n()) %>%
    ungroup() %>%
    mutate(
      confirmed = case_when(
        num_matches > 1 ~ 0,
        section_dist != 0 ~ 0,
        dist_sum == 0 ~ 1,
        (question_name_dist == 0 & question_text_dist == 0) |
          (question_name_dist == 0 & question_number_dist == 0) |
          (question_text_dist == 0 & question_number_dist == 0) ~ 1,
        TRUE ~ 0
      )
    ) %>%
    rename_with(
      ~ str_replace_all(., c("\\.x$" = x_year_chr, "\\.y$" = y_year_chr)),
      everything()
    ) %>%
    assert(
      is_uniq,
      !!paste0("question_id", x_year),
      error_fun = unconfirmed
    ) %>%
    assert(
      is_uniq,
      !!paste0("question_id", x_year),
      error_fun = unconfirmed
    )
  
  attr(combined, "years") <- years
  
  
  correct <- combined %>%
    filter(confirmed == 1)
  
  attr(correct, "db_vars") <- schema$linked
  
  check <- combined %>%
    filter(confirmed == 0)
  
  attr(check, "db_vars") <- schema$unlinked
  
  return(list("combined" = combined, "linked" = correct, "unlinked" = check))
}
