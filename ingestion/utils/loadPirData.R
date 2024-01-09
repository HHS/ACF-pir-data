loadPirData <- function(workbooks, log_file) {
  pkgs <- c("readxl", "dplyr", "janitor", "assertr")
  invisible(sapply(pkgs, require, character.only = T))
  
  
  workbooks <- future_map(
    workbooks,
    function(workbook) {
      sheets <- attr(workbook, "sheets")
      
      for (sheet in sheets) {
        
        if (grepl("Section", sheet)) {
          df <- loadPirSection(workbook, sheet)
        } else {
          df <- read_excel(workbook, sheet)
          if (sheet == "Reference") {
            df <- df %>%
              clean_names() %>%
              assert_rows(
                col_concat, is_uniq, question_number, question_name, 
                error_fun = duplicatedQuestionError
              )
          }
        }
        if (grepl("Program", sheet)) {
          sheet <- "program"
        }
        attr(workbook, make_clean_names(sheet)) <- df
      }
      attr(workbook, "configuration") <- NULL
      return(workbook)
    }
  )
  
  gc()
  return(workbooks)
}
