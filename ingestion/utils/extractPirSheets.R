# Extract sheets, add year and sheets as attributes
extractPirSheets <- function(workbooks, log_file) {
  pkgs <- c("furrr", "stringr")
  invisible(sapply(pkgs, require, character.only = T))
  
  sheets <- future_map(
    workbooks,
    function(workbook) {
      sheet_list <- excel_sheets(workbook)
      year <- stringr::str_extract(workbook, "(\\d+).(csv|xlsx?)", group = 1)
      attr(workbook, "year") <- year
      attr(workbook, "sheets") <- sheet_list
      return(workbook)
    }
  )
  
  return(sheets)
}