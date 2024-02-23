#' Merge Reference sheet to appended Sections
#' 
#' Extract question metadata from the Reference sheet and
#' create question data frame. Merge question data frame to
#' appended Section sheets created with appendPirSections.
#' 
#' @param workbooks A single workbook path, or list of workbook paths, returned
#' from `appendPirSections` (i.e. one that has data frame attributes).
#' @param log_file A data frame containing the log data. 
#' @returns A single workbook path, or list of workbook paths, with updated
#' "response", "unmatched_response", "question", and "unmatched_question" 
#' attributes.

mergePirReference <- function(workbooks, log_file) {
  require(dplyr)
  
  workbooks <- furrr::future_map(
    workbooks,
    function(workbook) {
      
      # Source the error functions
      rm(list = ls(pattern = "Error"))
      error_funs <- list.files(
        here("pir_ingestion", "utils"), 
        pattern = "Error.R$",
        full.names = T
      )
      for (i in seq(length(error_funs))) {
        source(error_funs[i], local = T)
      }
      
      # Extract data
      response <- attr(workbook, "response") %>%
        addUnmatched()
      
      response_vars <- names(response)
      
      question <- attr(workbook, "reference") %>%
        addUnmatched()
      
      # Set of unique questions
      question_nums <- unique(question$question_number)
      
      # Get the function environment
      func_env <- environment()
      
      # Check that reference has all questions
      response <- response %>%
        # Remove numeric strings added to uniquely identify questions
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
          error_fun = naNumberError
        ) %>%
        pipeExpr(
          assign("response_nums", unique(.$question_number), envir = func_env)
        ) %>%
        assertr::verify(
          length(setdiff(response_nums, question_nums)) == 0,
          error_fun = responseMergeError
        ) %>%
        # Merge question to response
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
          error_fun = missingQuestionError
        ) %>%
        select(-c(merge)) %>%
        assertr::assert(not_na, question_name, question_number)
      
      # Add section where missing
      question <- question %>%
        left_join(
          response %>%
            distinct(question_number, question_name, section_response),
          by = c("question_number", "question_name"),
          relationship = "one-to-one"
        ) 
      
      # Highlight unmatched questions
      unmatched_question <- question %>%
        filter(!is.na(unmatched))  %>%
        rename(reason = unmatched)
      

      for (table in c("response", "question", "unmatched_question")) {
        attr(workbook, table) <- get(table)
      }
      
      attr(workbook, "reference") <- NULL
      
      return(workbook)
    }
  )

  gc()
  return(workbooks)
}