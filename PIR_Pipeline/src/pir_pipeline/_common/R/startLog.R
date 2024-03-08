################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Create path to log file.
################################################################################


#' Create path to log file
#' 
#' `startLog` creates a log file to be used with `logMessage`.
#' 
#' @param path Absolute path to the log file.
#' @returns String containing the name of the log to be used.
#' @examples
#' # example code
#' startLog("hello_world.txt")

startLog <- function(table) {
  # Get the current timestamp
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  # Initialize the log data frame with columns
  log <- data.frame("run" = NULL, "timestamp" = NULL, "message" = NULL)
  # Set attributes for run timestamp and database table
  attr(log, "run") <- timestamp
  attr(log, "db") <- table
  # Return the initialized log
  return(log)
}
