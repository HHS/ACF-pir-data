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
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log <- data.frame("run" = NULL, "timestamp" = NULL, "message" = NULL)
  attr(log, "run") <- timestamp
  attr(log, "db") <- table
  return(log)
}
