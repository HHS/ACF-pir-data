################################################################################
## Written by: Reggie Gilliard
## Date: 11/10/2023
## Description: Extract sheets from a PIR workbook
################################################################################


#' Extract sheets from a PIR workbook
#' 
#' `extractPirSheets` extracts the names of worksheets contained in a PIR
#' workbook. These names, along with the year embedded in the workbook
#' path are stored as attributes of the object passed.
#' 
#' @param workbooks A single workbook path, or list of workbook paths, returned
#' from `loadPirData` (i.e. one that has data frame attributes).
#' @param log_file A data frame containing the log data.
#' @returns Workbook object(s) with "year" and "sheets" attributes containing
#' the year the data pertain to and the sheets in the workbook respectively.

extractPirSheets <- function(workbooks, log_file) {
  # Use future_map to process workbooks in parallel
  sheets <- furrr::future_map(
    workbooks,
    function(workbook) {
      # Read sheet names from the workbook
      sheet_list <- readxl::excel_sheets(workbook)
      # Extract year from workbook path
      year <- stringr::str_extract(workbook, "(\\d+).(csv|xlsx?)", group = 1)
      attr(workbook, "year") <- year
      attr(workbook, "sheets") <- sheet_list
      # Return the processed workbook
      return(workbook)
    }
  )
  
  
  gc()
  return(sheets)
}