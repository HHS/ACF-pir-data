# Establish DB connection ----
connectDB <- function(dblist, username, password, log_file, host = "localhost", port = 0) {
  pkgs <- c("RMariaDB", "purrr")
  invisible(sapply(pkgs, require, character.only = T))
  connections <- map(
    dblist,
    function(name) {
      tryCatch(
        {
          conn <- dbConnect(
            RMariaDB::MariaDB(), 
            dbname = name,
            host = host,
            port = port,
            username = dbusername, 
            password = dbpassword
          )
          logMessage(
            paste("Connection established to database", name, "successfully."),
            log_file
          )
          return(conn)
        },
        error = function(cnd) {
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
  return(connections)
}
