#' Merge Reference sheet to appended Sections
#' 
#' Extract question metadata from the Reference sheet and
#' create question data frame. Merge question data frame to
#' appended Section sheets created with appendPirSections.
#' 
#' @param df_list A list of data frames.
#' @param workbook The workbook that the current data come from.
#' @examples
#' # example code
#' mergePirReference(response_df, "test_wb.xlsx")

mergePirReference <- function(workbooks, log_file) {
  
  workbooks <- future_map(
    workbooks,
    function(workbook) {
      
      rm(list = ls(pattern = "Error"))
      error_funs <- list.files(
        here("ingestion", "utils"), 
        pattern = "Error.R$",
        full.names = T
      )
      for (i in seq(length(error_funs))) {
        source(error_funs[i], local = T)
      }
      
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
        attr(workbook, table) <- get(table)
      }
      
      attr(workbook, "reference") <- NULL
      logMessage("Successfully merged reference sheet(s).", log_file)
      gc()
      
      return(workbook)
    }
  )

  return(workbooks)
}