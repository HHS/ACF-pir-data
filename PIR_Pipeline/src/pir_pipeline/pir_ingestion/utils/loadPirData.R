#' Load all data from PIR workbook
#' 
#' `loadPirData` loads data from all worksheets of a given PIR workbook, or
#' list of workbooks. The configuration sheet is never used in the PIR
#' ingestion pipeline and is therefore dropped here.
#' 
#' @param workbooks A single workbook path, or list of workbook paths, returned
#' from `loadPirData` (i.e. one that has data frame attributes).
#' @param log_file A data frame containing the log data.
#' @returns A list of string objects with attributes corresponding for each
#' worksheet in the workbook identified by the object.

loadPirData <- function(workbooks, log_file) {
  require(dplyr)
  
  
  workbooks <- future_map(
    workbooks,
    function(workbook) {
      sheets <- attr(workbook, "sheets")
      
      for (sheet in sheets) {
        
        if (grepl("Section", sheet)) {
          df <- loadPirSection(workbook, sheet)
        } else {
          df <- readxl::read_excel(workbook, sheet)
          # Remove duplicated questions in Reference sheets
          if (sheet == "Reference") {
            df <- df %>%
              janitor::clean_names() %>%
              assertr::assert_rows(
                col_concat, is_uniq, question_number, question_name, 
                error_fun = duplicatedQuestionError
              )
          }
        }
        # Adjust name of Program Details sheets
        if (grepl("Program", sheet)) {
          sheet <- "program"
        }
        # Clean up sheet names for storage as attribute
        attr(workbook, make_clean_names(sheet)) <- df
      }
      attr(workbook, "configuration") <- NULL
      return(workbook)
    }
  )
  
  gc()
  return(workbooks)
}
