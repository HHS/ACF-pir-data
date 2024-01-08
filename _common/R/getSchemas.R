getSchemas <- function(conn, tables) {
  func_env <- environment()
  tryCatch(
    {
      schema <- list()
      walk(
        tables,
        function(table) {
          vars <- dbGetQuery(conn, paste("SHOW COLUMNS FROM", table))
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