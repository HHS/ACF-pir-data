#' Log status messages
#'
#' `logMessage` logs status messages within the ingestion pipeline.
#' 
#' @param message The message to be logged as a character string.
#' @param log String file path of the log to which to write the message.
#' @returns NULL
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