#' Merge Reference sheet to appended Sections
#' 
#' Extract question metadata from the Reference sheet and
#' create question data frame. Merge question data frame to
#' appended Section sheets created with appendPirSections.
#' 
#' @param df_list A list of data frames.
#' @param workbook The workbook that the current data come from.
#' @examples
#' mergePirReference(response_df, "<path>/<to>/<workbook>.xlsx")

mergePirReference <- function(df_list, workbook) {
  
  response <- df_list$response
  question <- df_list$question
  
  # Extract year
  yr <- stringr::str_extract(workbook, "(\\d+).xlsx", group = 1)
  
  # Get the function environment
  func_env <- environment()
  
  # Handle questions appearing in Section.* but not in Reference
  responseMergeError <- function(list_of_errors, data) {

    attr(data, "text_df") %>%
      filter(question_number %in% setdiff(response_vars, question_vars)) %>%
      transmute(
        question_text = "Variable not in Reference sheet.",
        question_name,
        question_number
      ) %>%
      bind_rows(question) %>%
      {assign("question", ., envir = func_env)}
    
    return(data)
  }
  
  missingQuestion <- function(list_of_errors, data) {
    
    mi_question_env <- environment()
    
    unmatched_response <- data %>%
      filter(merge != 3)
    
    diff_name <- unmatched_response %>%
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
    
    unmatched_question <- question %>%
      right_join(
        select(diff_name, question_number),
        by = "question_number"
      )
    
    question %>%
      filter(question_number %notin% unmatched_questions) %>%
      {assign("question", ., envir = func_env)}
    
    logMessage(
      paste0(
        "All data for the following variables has been omitted due to",
        "conflicts in the question name. Please check table unmatched_response",
        "and table unmatched_question for details about these records",
        "\n",
        paste(
          diff_name$question_number,
          "-",
          "Question name in the response table was",
          diff_name$question_name_response,
          ".",
          "Question name in the question table was",
          diff_name$question_name_question,
          ".",
          collapse = "\n"
        )
      )
    )
    
    assign(
      "df_list", 
      append(
        df_list, 
        list(
          "unmatched_response" = unmatched_response,
          "unmatched_question" = unmatched_question
        )
      ),
      envir = func_env
    )
    
    data %>%
      filter(merge == 3) %>%
      return()
  }
  
  # Set of unique questions
  question_vars <- unique(question$question_number)
  
  # Check that reference has all questions
  response <- response %>%
    # Remove numeric strings added to uniquely identify
    mutate(
      question_number = gsub("_\\d+$", "", question_number, perl = T),
      q_num_lower = trimws(tolower(question_number)),
      question_number = ifelse(
        grepl("^(n/a|n\\.?a\\.?)$", q_num_lower),
        "na",
        question_number
      )
    ) %>%
    assertr::verify(
      !any(question_number == "na"),
      error_fun = naNumber
    )
    pipeExpr(
      assign("response_vars", unique(.$question_number), envir = func_env)
    ) %>%
    assertr::verify(
      length(setdiff(response_vars, question_vars)) == 0,
      error_fun = responseMergeError
    ) %>%
    # Merge to get question_name
    left_join(
      attr(response, "text_df"),
      by = c("question_number"),
      relationship = "many-to-one"
    ) %>%
    assertr::verify(!is.na(question_name)) %>%
    # Merge to appended data
    left_join_check(
      question,
      by = c("question_number", "question_name"),
      relationship = "many-to-one"
    ) %>%
    assertr::verify(
      merge == 3,
      error_fun = missingQuestion
    ) %>%
    select(-c(merge))
    
  df_list[["question"]] <- question
  df_list[["response"]] <- response
  return(df_list)
}