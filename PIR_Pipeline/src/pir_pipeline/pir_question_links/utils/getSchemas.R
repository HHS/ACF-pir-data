################################################################################
## Written by: Reggie Gilliard
## Date: 01/02/2023
## Description: Script to get database schemas.
################################################################################


#' Get Database Schemas
#' 
#' This function retrieves the schemas of tables in the specified databases
#' from the provided database connections.
#' 
#' @param conn_list A list of database connection objects.
#' @param db_list A character vector of database names.
#' @param log_file Path to the log file.
#' @return A list of data frames, each containing the schema of tables in
#'         the corresponding database.
#' 

getSchemas <- function(conn_list, db_list) {
  
  # Map over database connections and names
  purrr::map2(
    conn_list,
    db_list,
    function(conn, db) {
      tryCatch(
        {
          # Retrieve list of tables in the database
          tables <- DBI::dbGetQuery(conn, paste("SHOW TABLES FROM", db))[[1]]
          # Log message indicating successful retrieval of table list
          logMessage(
            paste("List of tables in database", db, "obtained."), 
            log_file
          )
          # Map over tables to retrieve their schemas
          schema <- purrr::map(
            tables,
            function(table) {
              vars <- DBI::dbGetQuery(conn, paste("SHOW COLUMNS FROM", table))
              vars <- vars$Field
              return(vars)
            }
          ) %>%
            setNames(tables)
          # Log message indicating successful retrieval of table schemas
          logMessage("Table schemas obtained.", log_file)
          return(schema)
        },
        error = function(cnd) {
          # Log error message if unable to retrieve table list or schemas
          logMessage(
            paste("Failed to obtain list of tables/table schemas from database", db),
            log_file
          )
          errorMessage(cnd, log_file)
        }
      )
    }
  )
  
}
