genResponseSchema <- function(conn, year) {
  query <- paste0(
    "call createResponseTable(", year, ")"
  )
  dbExecute(conn, query)
}
