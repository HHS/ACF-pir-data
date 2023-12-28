linkQuestions <- function(df_list) {
  pkgs <- c("dplyr", "stringr", "assertr", "stringdist")
  invisible(sapply(pkgs, require, character.only = T))
  
  determineLink <- function(df) {
    df %>%
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
        error_fun = unconfirmed
      ) %>%
      assert(
        is_uniq,
        !!paste0("question_id", upper),
        error_fun = unconfirmed
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
