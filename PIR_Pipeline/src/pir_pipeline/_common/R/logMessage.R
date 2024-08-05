################################################################################
## Written by: Reggie Gilliard
## Date: 02/23/2024
## Description: Define a function to log status messages.
################################################################################


#' Log status messages
#'
#' `logMessage` logs status messages.
#' 
#' @param message The message to be logged as a character string.
#' @param log String file path of the log to which to write the message.
#' @returns NULL
#' @examples
#' # example code
#' logMessage("Hello world", "hello_world.txt")

logMessage <- function(message, log_file) {
  # Capture the function call
  func_call <- match.call()
  
  # Get the current timestamp
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  
  # Append the message and timestamp to the log file
  log_file <- dplyr::bind_rows(
    log_file,
    data.frame(
      list(
        "run" = attr(log_file, "run"), 
        "timestamp" = timestamp, 
        "message" = message
      )
    )
  )
  # Assign the updated log file to the global environment
  assign(paste(func_call$log_file), log_file, envir = .GlobalEnv)
}

