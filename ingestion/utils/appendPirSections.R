#' Append all "Section" sheets of PIR workbook
#' 
#' `appendPirSections` loads all sheets of a PIR data workbook
#' which contain the word "Section" and appends them. The resultant
#' data frame is returned in a list with name "response".
#' 
#' @param workbook Path to the workbook to load sheets from
#' @returns List of 1 element, response, containing the appended sheets.
#' @examples
#' # example code
#' appendPirSections(test_wb.xlsx)

appendPirSections <- function(workbooks, log_file) {
  
  workbooks <- future_map(
    workbooks,
    function(workbook) {
      sections <- grep("section", names(attributes(workbook)), value = T)
      attr(workbook, "response") <- bind_rows(attributes(workbook)[sections])
      attributes(workbook)[sections] <- NULL
      return(workbook)
    }
  )
  gc()
  logMessage("Successfully appended Section sheet(s).", log_file)
  return(workbooks)
}

