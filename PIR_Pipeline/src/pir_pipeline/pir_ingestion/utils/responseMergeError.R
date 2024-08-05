################################################################################
## Written by: Reggie Gilliard
## Date: 11/14/2023
## Description: Identify questions in response, but not in Reference.
################################################################################


#' Identify questions in response, but not in Reference
#' 
#' `responseMergeError` is a function intended for use with assertr.
#' It identifies variables that are in the response data, but not mentioned
#' in the reference sheet.
#' 
#' @param list_of_errors Assertr list of errors.
#' @param data Data frame
#' @returns question data frame with updated values for `unmatched`.

responseMergeError <- function(list_of_errors, data) {
  require(dplyr)
  
  data %>%
    filter(question_number %in% setdiff(response_nums, question_nums)) %>%
    transmute(
      question_name,
      question_number,
      unmatched = "Variable not in Reference sheet."
    ) %>%
    distinct() %>%
    bind_rows(question) %>%
    {assign("question", ., envir = func_env)}
  
  return(data)
}