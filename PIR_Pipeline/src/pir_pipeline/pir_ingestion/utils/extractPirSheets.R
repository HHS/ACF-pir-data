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
  
  sheets <- furrr::future_map(
    workbooks,
    function(workbook) {
      sheet_list <- readxl::excel_sheets(workbook)
      year <- stringr::str_extract(workbook, "(\\d+).(csv|xlsx?)", group = 1)
      attr(workbook, "year") <- year
      attr(workbook, "sheets") <- sheet_list
      return(workbook)
    }
  )
  
  
  gc()
  logMessage("Successfully extracted PIR sheets.", log_file)
  return(sheets)
}

# extractPirSheets <- function(workbooks) {
#   pkgs <- c("furrr", "stringr", "readxl")
#   invisible(sapply(pkgs, require, character.only = T))
#   
#   func <- function(workbook) {
#     sheet_list <- excel_sheets(workbook)
#     year <- stringr::str_extract(workbook, "(\\d+).(csv|xlsx?)", group = 1)
#     attr(workbook, "year") <- year
#     attr(workbook, "sheets") <- sheet_list
#     return(workbook)
#   }
#   
#   func_env <- environment()
#   updated_workbooks <- workbooks
#   
#   sheets <- future_map(
#     workbooks,
#     function(workbook) {
#       tryCatch(
#         {
#           workbook <- func(workbook)
#           return(workbook)
#         },
#         error = function(cnd) {
#           return(NULL)
#         }
#       )
#     }
#   )
#   
#   
#   gc()
#   # logMessage("Successfully extracted PIR sheets.", log_file)
#   return(dropNull(sheets))
# }