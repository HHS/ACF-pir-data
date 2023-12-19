#' Log status messages
#'
#' @param message The message to be logged.
#' @param log The log to which to write the message.
#' @examples
#' # example code
#' logMessage("Hello world", "hello_world.txt")

logMessage <- function(message, log) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  
  log_entry <- paste(timestamp, message, "\n")
  cat(
    log_entry,
    file = log, 
    append = TRUE
  )
}