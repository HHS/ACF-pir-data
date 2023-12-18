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
  
  addUnmatched <- function(data) {
    if ("unmatched" %notin% names(data)) {
      data <- mutate(data, unmatched = NA_character_)
    }
    return(data)
  }
  
  # Add questions appearing in Section.* but not in Reference
  responseMergeError <- function(list_of_errors, data) {

    data %>%
      filter(question_number %in% setdiff(response_nums, question_nums)) %>%
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
    
    logMessage(
      paste0(
        "All data for the following variables has been omitted due to ",
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
      )
    )
    
    data %>%
      mutate(unmatched = ifelse(mi_q_cond == 0, "Missing/mismatched question", unmatched)) %>%
      return()
  }
  
  naNumber <- function(list_of_errors, data) {

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
  
  response <- df_list$response %>%
    addUnmatched()
  
  question <- df_list$question %>%
    addUnmatched()
  
  response_vars <- names(response)
  
  # Extract year
  yr <- stringr::str_extract(workbook, "(\\d+).xlsx", group = 1)
  
  # Get the function environment
  func_env <- environment()
  
  # Set of unique questions
  question_nums <- unique(question$question_number)

  # Check that reference has all questions
  response <- response %>%
    # Remove numeric strings added to uniquely identify
    mutate(
      question_number = gsub("_\\d+$", "", question_number, perl = T),
      q_num_lower = trimws(tolower(question_number)),
      q_num_lower = ifelse(
        grepl("^(n/a|n\\.?a\\.?)$", q_num_lower),
        "na",
        q_num_lower
      )
    ) %>%
    assertr::verify(
      !any(q_num_lower == "na"),
      error_fun = naNumber
    ) %>%
    pipeExpr(
      assign("response_nums", unique(.$question_number), envir = func_env)
    ) %>%
    assertr::verify(
      length(setdiff(response_nums, question_nums)) == 0,
      error_fun = responseMergeError
    ) %>%
    # Merge to appended data
    left_join_check(
      question %>%
        select(-c(unmatched)),
      by = c("question_number", "question_name"),
      relationship = "many-to-one"
    ) %>%
    mutate(
      mi_q_cond = case_when(
        is.na(unmatched) & merge != 3 ~ 0,
        TRUE ~ 1
      )
    ) %>%
    assertr::verify(
      mi_q_cond == 1,
      error_fun = missingQuestion
    ) %>%
    select(-c(merge)) %>%
    assertr::assert(not_na, question_name, question_number)
  
  unmatched_response <- response %>%
    filter(!is.na(unmatched)) %>%
    rename(reason = unmatched)
  
  response <- response %>%
    filter(is.na(unmatched))

  # Remove unmatched questions
  unmatched_question <- question %>%
    filter(!is.na(unmatched))  %>%
    rename(reason = unmatched)
  
  question <- question %>%
    filter(is.na(unmatched))
  
  for (table in c("response", "question", "unmatched_question", "unmatched_response")) {
    df_list[[table]] <- get(table)
  }

  return(df_list)
}