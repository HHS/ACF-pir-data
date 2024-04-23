################################################################################
## Written by: Reggie Gilliard
## Date: 04/23/2024
## Description: Perform PIR data ingestion.
################################################################################


#' Perform PIR data ingestion 
#' 
#' `pirIngestOld` is a function that executes the entire data ingestion pipeline
#' for PIR data before 2008.
#' 
#' @param workbook A single workbook path.
#' @return NULL

pirIngestOld <- function(workbook) {

  # Extract PIR sheets
  tryCatch(
    {
      wb <- extractPirSheets(workbook, log_file)
      logMessage(
        paste0("Successfully extracted PIR sheets from ", workbook, "."),
        log_file
      )
    },
    error = function(cnd) {
      logMessage(
        paste0("Failed to extract PIR data sheets from ", workbook, "."), 
        log_file
      )
      errorMessage(cnd, log_file)
    }
  )
  
  # Load all data
  tryCatch(
    {
      wb <- loadData(wb, log_file)
      logMessage(
        paste0("Successfully loaded PIR data from ", workbook, "."),
        log_file
      )
    },
    error = function(cnd) {
      logMessage(
        paste0("Failed to load PIR data from ", workbook, "."),
        log_file
      )
      errorMessage(cnd, log_file)
    }
  )
  
  # Append sections into response data
  tryCatch(
    {
      wb <- cleanQuestion(wb, log_file)
      logMessage(
        paste0("Successfully cleaned question data from ", workbook, "."),
        log_file
      )
    },
    error = function(cnd) {
      logMessage(
        paste0("Failed to clean question data from ", workbook, "."),
        log_file
      )
      errorMessage(cnd, log_file)
    }
  )
  
  # Merge reference sheet to section sheets
  tryCatch(
    {
      wb <- cleanProgram(wb, log_file)
      logMessage(
        paste0("Successfully cleaned program data from ", workbook, "."),
        log_file
      )
    },
    error = function(cnd) {
      logMessage(
        paste0("Failed to clean program data from ", workbook, "."),
        log_file
      )
      errorMessage(cnd, log_file)
    }
  )
  
  tryCatch(
    {
      wb <- cleanResponse(wb, log_file)
      logMessage(
        paste0("Successfully cleaned response data from ", workbook, "."),
        log_file
      )
    },
    error = function(cnd) {
      logMessage(
        paste0("Failed to clean response data from ", workbook, "."),
        log_file
      )
      errorMessage(cnd, log_file)
    }
  )
  
  # Final cleaning
  tryCatch(
    {
      wb <- cleanPirData(wb, schema, log_file)
      logMessage(
        paste0("Successfully cleaned PIR data from ", workbook, "."),
        log_file
      )
    },
    error = function(cnd) {
      logMessage(
        paste0("Failed to clean PIR data from ", workbook, "."),
        log_file
      )
      errorMessage(cnd, log_file)
    }
  )

  # Write to DB ----
  
  # Write data
  tryCatch(
    {
      insertPirData(conn, wb, schema, log_file)
      logMessage(
        paste0("Successfully inserted data into DB from ", workbook, "."),
        log_file
      )
    },
    error = function(cnd) {
      logMessage(
        paste0("Failed to insert data into DB from ", workbook, "."),
        log_file
      )
      errorMessage(cnd, log_file)
    }
  )
  
  # Move Files
  tryCatch(
    {
      moveFiles(workbook, config$Processed)
      logMessage(
        paste0("Successfully moved file ", workbook, "to processsed directory."),
        log_file
      )
    },
    error = function(cnd) {
      logMessage(
        paste0("Failed to move file ", workbook, "."),
        log_file
      )
      errorMessage(cnd, log_file)
    }
  )
  # Perform garbage collection
  gc() 
}
