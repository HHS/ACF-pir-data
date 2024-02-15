#' Identify missing questions
#' 
#' `missingQuestionError` is a function intended for use with assertr.
#' When merging response and question data, if a question is not matched
#' then it will be added to the unmatched_questions data frame and
#' responses to that question will be added to the unmatched_responses
#' data frame.
#' 
#' @param list_of_errors Assertr list of errors.
#' @param data Data frame
#' @returns A data frame containing the variables in `mi_vars`.

missingQuestionError <- function(list_of_errors, data) {
  
  mi_question_env <- environment()
  
  # Create unmatched_questions and diff_name for outputting message
  diff_name <- data %>%
    filter(mi_q_cond == 0) %>%
    rename(question_name_response = question_name) %>%
    left_join(
      question,
      by = "question_number"
    ) %>%
    select(question_number, starts_with("question_name")) %>%
    rename(question_name_question = question_name) %>%
    distinct() %>%
    pipeExpr(
      assign(
        "unmatched_questions",
        unique(.$question_number),
        envir = mi_question_env
      )
    )
  
  # Update question data to exclude unmatched_questions
  question <- question %>%
    full_join_check(
      select(diff_name, question_number),
      by = "question_number"
    ) %>%
    mutate(
      unmatched = ifelse(merge == 3, "Missing/mismatched question", unmatched)
    ) %>%
    select(-c(merge))
  
  assign("question", question, envir = func_env)
  
  # Descriptive log message
  logMessage(
    paste0(
      "All data for the following variables, in workbook ",
      gsub(".*(?<=\\W)(\\w+.xlsx?)$", "\\1", workbook, perl = T),
      ", have been omitted due to ",
      "conflicts in the question name. Please check table unmatched_response ",
      "and table unmatched_question for details about these records",
      "\n",
      paste0(
        diff_name$question_number,
        " - ",
        "Question name in the response table was ",
        "'",
        diff_name$question_name_response,
        "'", 
        ". ",
        "Question name in the question table was ",
        diff_name$question_name_question,
        ".",
        collapse = "\n"
      )
    ), 
    log_file
  )
  
  data %>%
    mutate(unmatched = ifelse(mi_q_cond == 0, "Missing/mismatched question", unmatched)) %>%
    return()
}