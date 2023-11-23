mergePirReference <- function(response, workbook) {
  
  yr <- stringr::str_extract(workbook, "(\\d+).xlsx", group = 1)
  func_env <- environment()
  
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
      variable = gsub("_\\d+$", "", variable, perl = T)
    ) %>%
    pipeExpr(
      assign("response_vars", unique(.$variable), envir = func_env)
    ) %>%
    assertr::verify(
      length(setdiff(response_vars, question_vars)) == 0
    ) %>%
    # Merge to question_name
    left_join(
      attr(response, "text_df"),
      by = c("variable"),
      relationship = "many-to-one"
    ) %>%
    assertr::verify(!is.na(question_name)) %>%
    # Merge to appended data
    left_join(
      question,
      by = c("variable" = "question_number", "question_name"),
      relationship = "many-to-one"
    )
  return(list("response" = response, "question" = question))
}