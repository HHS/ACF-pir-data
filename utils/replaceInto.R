replaceInto <- function(conn, df, table) {
  
  dbExecute(conn, "SET foreign_key_checks = 0")
  
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
  # print(query)
  dbExecute(conn, query, params = unname(as.list(df)))
  logMessage(paste("Successfully inserted data into", table))
  
  dbExecute(conn, "SET foreign_key_checks = 1")
}