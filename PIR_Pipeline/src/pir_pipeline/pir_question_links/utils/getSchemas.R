getSchemas <- function(conn_list, db_list) {
  
  purrr::map2(
    conn_list,
    db_list,
    function(conn, db) {
      tryCatch(
        {
          tables <- DBI::dbGetQuery(conn, paste("SHOW TABLES FROM", db))[[1]]
          logMessage(
            paste("List of tables in database", db, "obtained."), 
            log_file
          )
          schema <- purrr::map(
            tables,
            function(table) {
              vars <- DBI::dbGetQuery(conn, paste("SHOW COLUMNS FROM", table))
              vars <- vars$Field
              return(vars)
            }
          ) %>%
            setNames(tables)
          logMessage("Table schemas obtained.", log_file)
          return(schema)
        },
        error = function(cnd) {
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
