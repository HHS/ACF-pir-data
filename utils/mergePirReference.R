#' Merge Reference sheet to appended Sections
#' 
#' Extract question metadata from the Reference sheet and
#' create question data frame. Merge question data frame to
#' appended Section sheets created with appendPirSections.
#' 
#' @param response The response data (appended Section sheets).
#' @param workbook The workbook that the current data come from.
#' @examples
#' mergePirReference(response_df, "<path>/<to>/<workbook>.xlsx")

mergePirReference <- function(response, workbook) {
  
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
  
  # Load reference sheet
  question <- readxl::read_excel(workbook, sheet = "Reference") %>%
    janitor::clean_names() %>%
    assert_rows(col_concat, is_uniq, question_number, question_name)
  
  # Set of unique questions
  question_vars <- unique(question$question_number)
  
  # Check that reference has all questions
  response <- response %>%
    # Remove numeric strings added to uniquely identify
    mutate(
      question_number = gsub("_\\d+$", "", question_number, perl = T)
    ) %>%
    pipeExpr(
      assign("response_vars", unique(.$question_number), envir = func_env)
    ) %>%
    assertr::verify(
      length(setdiff(response_vars, question_vars)) == 0,
      error_fun = responseMergeError
    ) %>%
    # Merge to question_name
    left_join(
      attr(response, "text_df"),
      by = c("question_number"),
      relationship = "many-to-one"
    ) %>%
    assertr::verify(!is.na(question_name)) %>%
    # Merge to appended data
    left_join(
      question,
      by = c("question_number", "question_name"),
      relationship = "many-to-one"
    )
  return(list("response" = response, "question" = question))
}
