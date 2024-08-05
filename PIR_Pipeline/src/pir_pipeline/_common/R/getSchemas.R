################################################################################
## Written by: Reggie Gilliard
## Date: 02/22/2024
## Description: Define a function to retrieve schemas.
################################################################################


#' Retrieve schemas for specified tables from a database connection.
#' 
#' The `getSchemas` function retrieves the schemas 
#' for specified tables from a given database connection.
#' 
#' @param conn An SQL connection to the database.
#' @param tables A character vector specifying the names of the tables.
#' @return A list containing schemas for each table.

getSchemas <- function(conn, tables) {
  # Define the environment
  func_env <- environment()
  tryCatch(
    {
      # Initialize an empty list to store schemas
      schema <- list()
      purrr::walk(
        tables,
        function(table) {
          vars <- DBI::dbGetQuery(conn, paste("SHOW COLUMNS FROM", table))
          vars <- vars$Field
          schema[[table]] <- vars
          assign("schema", schema, envir = func_env)
        }
      )
      logMessage("Schemas read from database.", log_file)
      return(schema)
    },
    error = function(cnd) {
      logMessage("Failed to read schemas from database.", log_file)
      logMessage("Failed to read schemas from database.", log_file)
      errorMessage(cnd, log_file)
    }
  )
}