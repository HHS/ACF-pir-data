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
  
  response_vars <- names(response)
  
  # Extract year
  yr <- stringr::str_extract(workbook, "(\\d+).xlsx", group = 1)
  
  # Get the function environment
  func_env <- environment()
  
  addUnmatched <- function(data) {
    if ("unmatched" %notin% names(data)) {
      data <- mutate(data, unmatched = NA_real_)
    }
    return(data)
  }
  
  # Update unmatched tables
  # updateUnmatched <- function(envir) {
  #   
  #   uu_env <- environment()
  #   tables <- c("unmatched_response", "unmatched_question")
  #   df_list <- get("df_list")
  #   
  #   entry_condition <- all(
  #     map_lgl(
  #       tables,
  #       function(table) {
  #         is.null(df_list[[table]])
  #       }
  #     )
  #   )
  #   if (entry_condition) {
  #     walk(
  #       tables,
  #       function(table) {
  #         assign(table, envir[[table]], envir = uu_env)
  #       }
  #     )
  #   } else {
  #     walk(
  #       tables,
  #       function(table) {
  #         if (!is.null(df_list[[table]])) {
  #           df <- bind_rows(
  #             df_list[["table"]],
  #             envir[["table"]]
  #           )
  #           assign(table, df, envir = uu_env)
  #         }
  #       }
  #     )
  #   }
  # 
  #   walk(
  #     tables,
  #     function(table) {
  #       df_list[[table]] <- uu_env[[table]]
  #       assign("df_list", df_list, envir = uu_env)
  #     }
  #   )
  #   
  #   assign(
  #     "df_list", 
  #     df_list,
  #     envir = func_env
  #   )
  # }
  
  # Add questions appearing in Section.* but not in Reference
  responseMergeError <- function(list_of_errors, data) {

    attr(data, "text_df") %>%
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
      addUnmatched() %>%
      full_join_check(
        select(diff_name, question_number),
        by = "question_number"
      ) %>%
      mutate(
        unmatched = ifelse(merge == 2, 1, unmatched)
      ) %>%
      select(-c(merge))
    
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
    
    # updateUnmatched(mi_question_env)
    
    data %>%
      mutate(unmatched = ifelse(mi_q_cond == 0, 1, unmatched)) %>%
      return()
  }
  
  naNumber <- function(list_of_errors, data) {

    naNum_env <- environment()

    question %>%
      addUnmatched() %>%
      mutate(
        q_num_lower = trimws(tolower(question_number)),
        q_num_lower = ifelse(
          grepl("^(n/a|n\\.?a\\.?)$", q_num_lower),
          "na",
          q_num_lower
        ),
        unmatched = ifelse(q_num_lower == "na", 1, unmatched)
      ) %>%
      {assign("question", ., envir = func_env)}
    
    # updateUnmatched(naNum_env)
    
    data %>%
      mutate(unmatched = ifelse(q_num_lower == "na", 1, unmatched)) %>%
      return()
  }
  
  
  # Set of unique questions
  question_nums <- unique(question$question_number)
  
  # Check that reference has all questions
  response <- response %>%
    addUnmatched() %>%
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
    # Merge to get question_name
    left_join(
      attr(response, "text_df"),
      by = c("question_number"),
      relationship = "many-to-one"
    ) %>%
    mutate(
      name_cond = case_when(
        unmatched != 1 & is.na(question_name) ~ 0,
        TRUE ~ 1
      )
    ) %>%
    assertr::verify(
      name_cond == 1
    ) %>%
    # Merge to appended data
    left_join_check(
      filter(question, unmatched != 1) %>%
        select(-c(unmatched)),
      by = c("question_number", "question_name"),
      relationship = "many-to-one"
    ) %>%
    mutate(
      mi_q_cond = case_when(
        unmatched != 1 & merge != 3 ~ 0,
        TRUE ~ 1
      )
    ) %>%
    assertr::verify(
      mi_q_cond == 1,
      error_fun = missingQuestion
    ) %>%
    select(-c(merge)) 
  
  unmatched_response <- response %>%
    filter(unmatched == 1)
  
  response <- response %>%
    filter(unmatched != 1 | is.na(unmatched))

  # Remove unmatched questions
  unmatched_question <- question %>%
    filter(unmatched == 1)
  question <- question %>%
    filter(unmatched != 1 | is.na(unmatched))
  
  for (table in c("response", "question", "unmatched_question", "unmatched_response")) {
    df_list[[table]] <- get(table)
  }

  return(df_list)
}