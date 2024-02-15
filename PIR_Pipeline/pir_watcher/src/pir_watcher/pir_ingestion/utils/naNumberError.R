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
  
  naNum_env <- environment()
  
  question %>%
    mutate(
      q_num_lower = trimws(tolower(question_number)),
      q_num_lower = ifelse(
        grepl("^(n/a|n\\.?a\\.?)$", q_num_lower),
        "na",
        q_num_lower
      ),
      unmatched = ifelse(q_num_lower == "na", "NA question number", unmatched)
    ) %>%
    {assign("question", ., envir = func_env)}
  
  data %>%
    mutate(unmatched = ifelse(q_num_lower == "na", "NA question number", unmatched)) %>%
    return()
}