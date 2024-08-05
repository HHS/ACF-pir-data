################################################################################
## Written by: Reggie Gilliard
## Date: 11/10/2023
## Description: Append all "Section" sheets of PIR workbook
################################################################################


#' Append all "Section" sheets of PIR workbook
#' 
#' `appendPirSections` appends all sheets of a PIR workbook containing the word
#' 'section'. The resultant data frame is returned
#' as the "response" attribute of the object passed.
#' 
#' @param workbooks A single workbook path, or list of workbook paths, returned
#' from `loadPirData` (i.e. one that has data frame attributes).
#' @param log_file A data frame containing the log data. 
#' @returns Workbook object(s) with "response" attribute containing response
#' data

appendPirSections <- function(workbooks, log_file) {
  
  workbooks <- purrr::map(
    workbooks,
    function(workbook) {
      # Extract and append data sets with section in name
      sections <- grep("section", names(attributes(workbook)), value = T)
      attr(workbook, "response") <- dplyr::bind_rows(attributes(workbook)[sections])
      attributes(workbook)[sections] <- NULL
      return(workbook)
    }
  )
  
  gc()
  return(workbooks)
  
}