# Function to log an error message
errorMessage <- function(error, log_file) {
  error_message <- paste("Error:", conditionMessage(error))
  log_file <- logMessage(error_message, log_file)
  writeLog(log_file)
  stop(error_message)
}