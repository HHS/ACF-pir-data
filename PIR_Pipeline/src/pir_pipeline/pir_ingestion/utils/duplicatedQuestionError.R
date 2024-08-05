################################################################################
## Written by: Reggie Gilliard
## Date: 11/10/2023
## Description: Handle duplicated questions
################################################################################


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
  # Load the dplyr package for data manipulation
  require(dplyr)
  # Initialize an empty list to store output
  output <- list()
  # Get the names of the variables in the original data frame
  out_vars <- names(data)
  
  # Extract unique columns
  error_df <<- list_of_errors[[1]]$error_df
  grouping_cols <- gsub("~", "", unique(error_df$column))
  
  # Keep only unique questions
  data %>%
    group_by(!!!syms(grouping_cols)) %>%
    mutate(
      # Add a column 'num_dups' with the number of duplicates in each group
      num_dups = n(),
      # Add a column 'index' with the row number within each group
      index = row_number(),
      min_order = min(question_order),
      # Verify index conditions
      index_verify = case_when(
        index == 1 & question_order == min_order ~ 1,
        index != 1 & question_order != min_order ~ 1,
        TRUE ~ 0
      )
    ) %>%
    # Verify that index_verify is equal to 1
    assertr::verify(index_verify == 1) %>%
    filter(
      index == 1
    ) %>%
    select(all_of(out_vars)) %>%
    # Assert that rows are unique based on specified columns
    assertr::assert_rows(col_concat, is_uniq, !!!syms(grouping_cols)) %>%
    return()
}


