################################################################################
## Written by: Reggie Gilliard
## Date: 11/10/2023
## Description: Clean PIR data
################################################################################



#' Perform cleaning to prepare data for MySQL database
#' 
#' `cleanPirData` performs several cleaning steps, such as hashing values,
#' checking for NAs, and removing extraneous variables, to prepare the data
#' for insertion into the MySQL database.
#' 
#' @param workbooks A single workbook path, or list of workbook paths, returned
#' from `loadPirData` (i.e. one that has data frame attributes).
#' @param log_file A data frame containing the log data. 
#' @param schema A list of character vectors defining the columns that should
#' be kept (or added) to the corresponding data frame.

cleanPirData <- function(workbooks, schema, log_file) {
  # Load required packages
  require(dplyr)
  # Process each workbook in parallel
  workbooks <- furrr::future_map(
    workbooks,
    function(workbook) {
      # Load additional utility functions
      source(here::here("pir_ingestion", "utils", "addPirVars.R"), local = T)
      # Define environment
      func_env <- environment()
      
      # Create vectors of variables
      purrr::walk(
        names(schema),
        function(table) {
          assign(
            paste0(tolower(table), "_vars"),
            schema[[table]],
            envir = func_env
          )
        }
      )
      
      # Remove data frames with 0 observations
      df_list <- attributes(workbook)
      yr <- as.numeric(df_list$year)
      df_list <- df_list[purrr::map_lgl(df_list, function(df) !is.null(nrow(df)) && nrow(df) > 0)]
      tables <- names(df_list)
      
      # Clean response table data
      map(
        tables,
        function(table) {
          # Get column names for the current table
          vars <- get(paste0(tolower(table), "_vars"), envir = func_env)
          # Check if the table is a response table
          if (grepl("response", table)) {
            df <- df_list[[table]] %>%
              # Clean column names
              janitor::clean_names() %>%
              rename(
                program_type = type
              ) %>%
              assertr::assert(not_na, grant_number, program_number, program_type) %>%
              assertr::assert(not_na, question_number, question_name) %>%
              # Add new columns
              mutate(
                year = yr,
                uid_hash = paste0(grant_number, program_number, program_type),
                uid = hashVector(uid_hash),
                question_id_hash = paste0(question_number, question_name),
                question_id = hashVector(question_id_hash)
              ) %>%
              select(all_of(vars))
            # Assign cleaned data frame back to the workbook
            attr(workbook, table) <- df
            assign("workbook", workbook, envir = func_env)
            
          } else if (grepl("question", table)) {
            
            df <- df_list[[table]] %>%
              assertr::assert(not_na, question_number, question_name) %>%
              # Add new columns
              mutate(
                section = case_when(
                  grepl("^(\\w)\\..*", question_number) ~ gsub("^(\\w)\\..*", "\\1", question_number, perl = T),
                  !is.na(section_response) ~ section_response,
                  TRUE ~ NA
                )
              ) %>%
              # Rename columns
              rename(
                question_type = type
              ) %>%
              mutate(
                year = yr,
                question_id_hash = paste0(question_number, question_name),
                question_id = hashVector(question_id_hash)
              ) %>%
              # Evaluate expression in specified environment
              pipeExpr(
                assign(
                  "mi_vars",
                  setdiff(question_vars, names(.)),
                  envir = func_env
                )
              ) %>%
              # Verify condition
              assertr::verify(
                length(mi_vars) == 0,
                error_fun = addPirVars
              ) %>%
              distinct(question_id, year, .keep_all = T) %>%
              select(all_of(vars))
            
            attr(workbook, table) <- df
            assign("workbook", workbook, envir = func_env)
            
          } else if (grepl("program", table)) {
            
            df <- df_list[[table]] %>%
              janitor::clean_names() %>%
              assertr::assert(not_na, grant_number, program_number, program_type) %>%
              rename(
                program_zip1 = program_zip_code,
                program_zip2 = program_zip_4,
                program_phone = program_main_phone_number,
                program_email = program_main_email
              ) %>%
              mutate(
                year = yr,
                uid_hash = paste0(grant_number, program_number, program_type),
                uid = hashVector(uid_hash),
                region = as.numeric(gsub("\\D+", "", region, perl = TRUE))
              ) %>%
              # Evaluate expression in specified environment
              pipeExpr(
                assign(
                  "mi_vars",
                  setdiff(program_vars, names(.)),
                  envir = func_env
                )
              ) %>%
              # Verify condition
              assertr::verify(
                length(mi_vars) == 0,
                error_fun = addPirVars
              ) %>%
              distinct(uid, year, .keep_all = T) %>%
              select(all_of(program_vars))
            
            attr(workbook, table) <- df
            assign("workbook", workbook, envir = func_env)
            
          } else {
            # If the table does not match any specific pattern, remove it
            attr(workbook, table) <- NULL
            assign("workbook", workbook, envir = func_env)
            
          }
        }
      )
      
      # Remove data frames with 0 rows again
      workbook_attr <- attributes(workbook)
      attributes(workbook) <- workbook_attr[
        purrr::map_lgl(workbook_attr, function(df) !is.data.frame(df) || nrow(df) > 0)
      ]
      # Return the cleaned workbook
      return(workbook) 
    }
  )
  # Perform garbage collection to free up memory
  gc()
  return(workbooks)
}
