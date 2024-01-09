#' Perform cleaning to prepare data for MySQL database
#' 
#' `cleanPirData` performs several cleaning steps, such as hashing values,
#' checking for NAs, and removing extraneous variables, to prepare the data
#' for insertion into the MySQL database.
#' 
#' @param df_list A list of data frames.
#' @param schema A list of character vectors defining the columns that should
#' kept (or added) to the corresponding df in `df_list`.
#' @param yr Year from which the data in `df_list` come.
#' @examples
#' # example code
#' cleanPirData(test_df_list, test_schema, test_yr)
cleanPirData <- function(workbooks, schema, log_file) {
  
  workbooks <- future_map(
    workbooks,
    function(workbook) {
      
      func_env <- environment()
      
      # Create vectors of variables
      walk(
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
      df_list <- df_list[map_lgl(df_list, function(df) !is.null(nrow(df)) && nrow(df) > 0)]
      tables <- names(df_list)
      
      # Clean response table data
      map(
        tables,
        function(table) {
          vars <- get(paste0(tolower(table), "_vars"), envir = func_env)
          
          if (grepl("response", table)) {
            df <- df_list[[table]] %>%
              janitor::clean_names() %>%
              rename(
                program_type = type
              ) %>%
              assertr::assert(not_na, grant_number, program_number, program_type) %>%
              assertr::assert(not_na, question_number, question_name) %>%
              mutate(
                year = yr,
                uid_hash = paste0(grant_number, program_number, program_type),
                uid = hashVector(uid_hash),
                question_id_hash = paste0(question_number, question_name),
                question_id = hashVector(question_id_hash)
              ) %>%
              select(all_of(vars))
            
            attr(workbook, table) <- df
            assign("workbook", workbook, envir = func_env)
            
          } else if (grepl("question", table)) {
            
            df <- df_list[[table]] %>%
              assertr::assert(not_na, question_number, question_name) %>%
              mutate(
                section = gsub("^(\\w).*", "\\1", question_number, perl = T)
              ) %>%
              rename(
                question_type = type
              ) %>%
              mutate(
                year = yr,
                question_id_hash = paste0(question_number, question_name),
                question_id = hashVector(question_id_hash)
              ) %>%
              pipeExpr(
                assign(
                  "mi_vars",
                  setdiff(question_vars, names(.)),
                  envir = func_env
                )
              ) %>%
              assertr::verify(
                length(mi_vars) == 0,
                error_fun = addPirVars
              ) %>%
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
                uid = hashVector(uid_hash)
              ) %>%
              pipeExpr(
                assign(
                  "mi_vars",
                  setdiff(program_vars, names(.)),
                  envir = func_env
                )
              ) %>%
              assertr::verify(
                length(mi_vars) == 0,
                error_fun = addPirVars
              ) %>%
              select(all_of(program_vars))
            
            attr(workbook, table) <- df
            assign("workbook", workbook, envir = func_env)
            
          } else {
            
            attr(workbook, table) <- NULL
            assign("workbook", workbook, envir = func_env)
            
          }
        }
      )
      
      workbook_attr <- attributes(workbook)
      attributes(workbook) <- workbook_attr[
        map_lgl(workbook_attr, function(df) !is.null(nrow(df)) && nrow(df) > 0)
      ]
      return(workbook)
    }
  )
  gc()
  logMessage("Successfully cleaned PIR data.", log_file)
  return(workbooks)
}
