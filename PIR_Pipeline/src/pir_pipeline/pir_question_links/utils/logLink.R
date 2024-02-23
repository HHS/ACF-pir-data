logLink <- function(base_id, link_id, type) {
  
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  
  link_log <-  data.frame(
    "timestamp" = timestamp,
    "base_id" = base_id,
    "linked_id" = link_id,
    "type" = type
  )
  
  log_conn <- dbConnect(RMariaDB::MariaDB(), dbname = "pir_logs", username = dbusername, password = dbpassword)
  replaceInto(log_conn, link_log, "pir_manual_question_link")
  dbDisconnect(log_conn)
}
