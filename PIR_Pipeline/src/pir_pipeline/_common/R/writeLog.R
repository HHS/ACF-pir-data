writeLog <- function(log_file) {
  
  # Establish connection to log db and insert
  table <- attr(log_file, "db")
  log_conn <- dbConnect(RMariaDB::MariaDB(), dbname = "pir_logs", username = dbusername, password = dbpassword)
  replaceInto(log_conn, log_file, table)
  dbDisconnect(log_conn)
}
