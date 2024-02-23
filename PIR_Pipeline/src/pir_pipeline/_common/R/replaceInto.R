#' Generate and execute "REPLACE INTO" MySQL query
#' 
#' `replaceInto` generates a "REPLACE INTO" query for `table` using data `df`.
#' 
#' @param conn Database connection.
#' @param df Data frame.
#' @param table Name of the table that data from `df` should be inserted into.
#' @returns NULL
#' @examples
#' # example code
#' conn <- DBI::dbConnect(
#'   RMariaDB::MariaDB(), 
#'   dbname = "test_db", 
#'   username = test_username, 
#'   password = test_password
#' )
#' replaceInto(conn, test_df, "test")
replaceInto <- function(conn, df, table, log_file = NULL) {
  
  DBI::dbExecute(conn, "SET foreign_key_checks = 0")
  DBI::dbExecute(conn, "SET autocommit = 0")
  
  query <- paste(
    "REPLACE INTO",
    table,
    "(",
    paste(names(df), collapse = ","),
    ")",
    "VALUES",
    "(",
    paste0(
      "?",
      vector(mode = "character", length = length(names(df))),
      collapse = ","
    ),
    ")"
  )
  
  DBI::dbExecute(conn, query, params = unname(as.list(df)))
  if (!is.null(log_file)) {
    logMessage(paste("Successfully inserted data into", table), log_file)
  }
  
  DBI::dbExecute(conn, "SET foreign_key_checks = 1")
  DBI::dbExecute(conn, "COMMIT")
}