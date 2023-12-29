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

logMessage <- function(message, log_file) {
  func_call <- match.call()
  
  pkgs <- c("dplyr")
  invisible(sapply(pkgs, require, character.only = T))
  
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  
  log_file <- bind_rows(
    log_file,
    data.frame(
      list(
        "run" = attr(log_file, "run"), 
        "timestamp" = timestamp, 
        "message" = message
      )
    )
  )
  
  assign(paste(func_call$log_file), log_file, envir = .GlobalEnv)
}

