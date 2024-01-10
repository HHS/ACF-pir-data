appendPirData <- function(workbooks, tables, log_file) {
  df_list <- map(
    tables,
    function(table) {
      df <- map(workbooks, function(workbook) attr(workbook, table)) %>%
        bind_rows()
    }
  )
  names(df_list) <- tables
  
  df_list$program <- df_list$program %>%
    distinct(uid, year, .keep_all = T)
  
  df_list$question <- df_list$question %>%
    distinct(question_id, year, .keep_all = T)
  
  gc()
  logMessage("Successfully PIR data across years.", log_file)
  return(df_list)
}