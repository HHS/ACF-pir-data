replaceInto <- function(conn, df, table) {
  
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
}