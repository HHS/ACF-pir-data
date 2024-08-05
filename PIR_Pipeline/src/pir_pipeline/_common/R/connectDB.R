################################################################################
## Written by: Reggie Gilliard
## Date: 02/23/2024
## Description: Establish DB connection
################################################################################


#' Connect to a database and log the connection status.
#' 
#' The `connectDB` function establishes connections to a databases 
#' specified in the `dblist` argument. It logs the connection status, 
#' including successful connections and any connection failures.
#' 
#' @param dblist A string of database names.
#' @param username Username for database authentication.
#' @param password Password for database authentication.
#' @param log_file Path to the log file for recording connection status.
#' @param host Database host address (default is "localhost").
#' @param port Database port number (default is 0).
#' @return A named list of database connections.

connectDB <- function(dblist, username, password, log_file, host = "localhost", port = 0) {
  # Map through each database connection parameter in the list
  connections <- purrr::map(
    dblist,
    function(name) {
      tryCatch(
        {
          # Establish a database connection
          conn <- DBI::dbConnect(
            RMariaDB::MariaDB(), 
            dbname = name,
            host = host,
            port = port,
            username = dbusername, 
            password = dbpassword
          )
          # Log successful connection
          logMessage(
            paste("Connection established to database", name, "successfully."),
            log_file
          )
          return(conn)
        },
        error = function(cnd) {
          # Log connection failure and error message
          logMessage(
            paste("Failed to establish connection to database", name, "."),
            log_file
          )
          errorMessage(cnd, log_file)
        }
      )
    }
  )
  connections <- setNames(connections, dblist)
  # Return the connections
  return(connections)
}
