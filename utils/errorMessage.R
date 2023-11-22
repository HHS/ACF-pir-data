# Function to log an error message
errorMessage <- function(error) {
  error_message <- paste("Error:", conditionMessage(error))
  logMessage(error_message)
  stop(error_message)
}