pirIngest <- function(workbook) {
  
  tryCatch(
    {
      wb_appended <- extractPirSheets(workbook, log_file)
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
      wb_appended <- loadPirData(wb_appended, log_file)
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
      wb_appended <- appendPirSections(wb_appended, log_file)
      logMessage(
        paste0("Successfully appended Section sheet(s) from ", workbook, "."),
        log_file
      )
    },
    error = function(cnd) {
      logMessage(
        paste0("Failed to append Section sheet(s) from ", workbook, "."),
        log_file
      )
      errorMessage(cnd, log_file)
    }
  )
  
  # Merge reference sheet to section sheets
  tryCatch(
    {
      wb_appended <- mergePirReference(wb_appended, log_file)
      logMessage(
        paste0("Successfully merged reference sheet(s) from ", workbook, "."),
        log_file
      )
    },
    error = function(cnd) {
      logMessage(
        paste0("Failed to merge Reference sheet(s) from ", workbook, "."),
        log_file
      )
      errorMessage(cnd, log_file)
    }
  )
  
  # Final cleaning
  tryCatch(
    {
      wb_appended <- cleanPirData(wb_appended, schema, log_file)
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
      insertPirData(conn, wb_appended, schema, log_file)
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
      moveFiles(wb_appended, config$Processed)
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
  gc()
}