################################################################################
## Written by: Reggie Gilliard
## Date: 01/02/2023
## Description: Logs a link between two questions.
################################################################################


#' Log Link
#' 
#' Logs a link between two questions.
#' 
#' @param base_id The ID of the base question.
#' @param link_id The ID of the linked question.
#' @param type The type of link.
#' 

logLink <- function(base_id, link_id, type) {
  # Get current timestamp
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  # Create data frame with link information
  link_log <-  data.frame(
    "timestamp" = timestamp,
    "base_id" = base_id,
    "linked_id" = link_id,
    "type" = type
  )
  # Connect to the logs database
  log_conn <- dbConnect(RMariaDB::MariaDB(), dbname = "pir_logs", username = dbusername, password = dbpassword)
  # Replace existing entry with the new log information
  replaceInto(log_conn, link_log, "pir_manual_question_link")
  # Disconnect from the logs database
  dbDisconnect(log_conn)
}
