loadQuestionProgram <- function(df_lists, workbooks, log_file) {
  
  loadData <- function(df_list, workbook) {
    duplicatedQuestion <- function(list_of_errors, data) {
      
      output <- list()
      
      out_vars <- names(data)
      
      # Extract unique columns
      error_df <<- list_of_errors[[1]]$error_df
      grouping_cols <- gsub("~", "", unique(error_df$column))
      
      # Keep only unique questions
      data %>%
        group_by(!!!syms(grouping_cols)) %>%
        mutate(
          num_dups = n(),
          index = row_number(),
          min_order = min(question_order),
          index_verify = case_when(
            index == 1 & question_order == min_order ~ 1,
            index != 1 & question_order != min_order ~ 1,
            TRUE ~ 0
          )
        ) %>%
        assertr::verify(index_verify == 1) %>%
        filter(
          index == 1
        ) %>%
        select(all_of(out_vars)) %>%
        assertr::assert_rows(col_concat, is_uniq, !!!syms(grouping_cols)) %>%
        return()
    }
    
    # Load reference sheet
    question <- readxl::read_excel(workbook, sheet = "Reference") %>%
      janitor::clean_names() %>%
      assert_rows(
        col_concat, is_uniq, question_number, question_name, 
        error_fun = duplicatedQuestion
      )
    
    # Load program sheet
    program <- readxl::read_excel(workbook, sheet = "Program Details")
    
    df_list <- append(df_list, list("question" = question, "program" = program))
    return(df_list)
  }
  
  tryCatch(
    {
      wb_appended <- future_map2(
        df_lists,
        workbooks,
        loadData
      )
      logMessage("Successfully loaded reference and program sheets.", log_file)
      gc()
      return(wb_appended)
    },
    error = function(cnd) {
      logMessage("Failed to load reference and/or program sheet.", log_file)
      errorMessage(cnd, log_file)
    }
  )
}