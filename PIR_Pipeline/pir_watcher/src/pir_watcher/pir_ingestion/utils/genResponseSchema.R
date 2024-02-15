#' Generate a response table schema for the present year
#' 
#' `genResponseSchema` executes the createResposneTable stored
#' procedure to create a new response schema for the present year.
#' 
#' @param conn An SQL connection (to the PIR database).
#' @param year The year for which to create a response table.
#' @returns NULL

genResponseSchema <- function(conn, year) {
  query <- paste0(
    "call createResponseTable(", year, ")"
  )
  dbExecute(conn, query)
}
