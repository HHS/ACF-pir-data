################################################################################
## Written by: Reggie Gilliard
## Date: 02/23/2024
## Description: Define a function to log an error message and stop execution.
################################################################################


#' Function to log an error message and stop execution.
#' 
#' The `errorMessage` function logs an error message to a specified log file
#' and stops execution by throwing an error.
#' 
#' @param error The error object containing the error message.
#' @param log_file Path to the log file for recording the error message.
#' @return This function stops execution by throwing an error.

errorMessage <- function(error, log_file) {
  # Extract the error message from the error object
  error_message <- paste("Error:", conditionMessage(error))
  # Log the error message to the specified log file
  log_file <- logMessage(error_message, log_file)
  # Write to the log file
  writeLog(log_file)
  # Stop execution by throwing an error with the error message
  stop(error_message)
}