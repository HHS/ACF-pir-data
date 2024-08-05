################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Write to log file.
################################################################################


#' Write log data to the database.
#' 
#' The `writeLog` function establishes a connection to the log database, inserts log data 
#' from the specified log file into the corresponding table, and then disconnects from the database.
#' 
#' @param log_file The log data frame to be written to the database.
#' @return NULL

writeLog <- function(log_file) {
  
  # Establish connection to log db and insert
  table <- attr(log_file, "db")
  log_conn <- DBI::dbConnect(
    RMariaDB::MariaDB(), dbname = "pir_logs", 
    username = dbusername, password = dbpassword
  )
  replaceInto(log_conn, log_file, table)
  DBI::dbDisconnect(log_conn)
}
