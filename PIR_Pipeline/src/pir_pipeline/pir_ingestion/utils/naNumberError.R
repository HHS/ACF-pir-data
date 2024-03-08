################################################################################
## Written by: Reggie Gilliard
## Date: 11/14/2023
## Description: Extract questions with missing question_number.
################################################################################


#' Extract questions with missing question_number
#' 
#' `naNumberError` is a function intended for use with assertr.
#' It identifies questions with NA numbers.
#' 
#' @param list_of_errors Assertr list of errors.
#' @param data Data frame
#' @returns question and response data frames with updated values for 
#' `unmatched`.

naNumberError <- function(list_of_errors, data) {
  # Load the dplyr package
  require(dplyr)
  # Create an environment
  naNum_env <- environment()
  
  question %>%
    mutate(
      # Lowercase and trim question numbers
      q_num_lower = trimws(tolower(question_number)),
      q_num_lower = ifelse(
        # Check if question number is "N/A"
        grepl("^(n/a|n\\.?a\\.?)$", q_num_lower),
        "na",
        q_num_lower
      ),
      unmatched = ifelse(q_num_lower == "na", "NA question number", unmatched)
    ) %>%
    # Assign modified question data
    {assign("question", ., envir = func_env)}
  # Return the modified data frame
  data %>%
    mutate(unmatched = ifelse(q_num_lower == "na", "NA question number", unmatched)) %>%
    return()
}