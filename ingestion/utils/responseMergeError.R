# Add questions appearing in Section.* but not in Reference
responseMergeError <- function(list_of_errors, data) {
  
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