#' Handle duplicated questions
#' 
#' `duplicatedQuestionError` is a function intended for use with assertr.
#' If the data being imported from a "Reference" sheet have duplicated
#' questions, this function removes them returning only unique questions.
#' 
#' @param list_of_errors Assertr list of errors.
#' @param data Data frame
#' @returns Data frame, unique by columns in assert call.

duplicatedQuestionError <- function(list_of_errors, data) {
  require(dplyr)
  
  output <- list()
  
  out_vars <- names(data)
  
  # Extract unique columns
  error_df <<- list_of_errors[[1]]$error_df
  grouping_cols <- gsub("~", "", unique(error_df$column))
  
  # Keep only unique questions
  data %>%
    group_by(!!!syms(grouping_cols)) %>%
    mutate(
      num_dups = n(),
      index = row_number(),
      min_order = min(question_order),
      index_verify = case_when(
        index == 1 & question_order == min_order ~ 1,
        index != 1 & question_order != min_order ~ 1,
        TRUE ~ 0
      )
    ) %>%
    assertr::verify(index_verify == 1) %>%
    filter(
      index == 1
    ) %>%
    select(all_of(out_vars)) %>%
    assertr::assert_rows(col_concat, is_uniq, !!!syms(grouping_cols)) %>%
    return()
}