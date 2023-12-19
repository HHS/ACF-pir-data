#' Create path to log file
#' 
#' `startLog` creates a log file to be used with `logMessage`.
#' 
#' @param path Absolute path to the log file.
#' @returns String containing the name of the log to be used.
#' @examples
#' # example code
#' startLog("hello_world.txt")

startLog <- function(path) {
  datetime <- format(Sys.time(), "%Y%m%d_%H_%M_%S")
  log_file <- file.path(path, paste0("ingestion_log_", datetime, ".txt"))
  return(log_file)
}
