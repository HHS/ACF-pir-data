# Function to log messages to a file
logMessage <- function(message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- paste(timestamp, message, "\n")
  date <- format(Sys.Date(), "%Y%m%d")
  logdir <- file.path(logdir, "automated_pipeline_logs")
  cat(
    log_entry, 
    file = file.path(logdir, paste0("ingestion_log", "_", date, ".txt")), 
    append = TRUE
  )
}