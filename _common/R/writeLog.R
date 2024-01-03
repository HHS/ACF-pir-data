writeLog <- function(log_file) {
  # Make path and create folders if needed
  ingestion_log_path <- attr(log_file, "path")
  target_db <- attr(log_file, "db")
  try(
    dir.create(
      ingestion_log_path,
      showWarnings = F,
      recursive = T
    ),
    silent = T
  )
  
  # Write csv log
  file_name <- paste0(attr(log_file, "run"), ".csv")
  file_name <- gsub("-|\\s|:", "_", file_name, perl = T)
  
  write.csv(
    log_file,
    file.path(
      ingestion_log_path, 
      file_name
    ),
    row.names = F
  )
  
  # Establish connection to log db and insert
  log_conn <- dbConnect(RMariaDB::MariaDB(), dbname = "pir_logs", username = dbusername, password = dbpassword)
  replaceInto(log_conn, log_file, target_db)
  dbDisconnect(log_conn)
}
