################################################################################
## Written by: Reggie Gilliard
## Date: 01/02/2024
## Description: Update the unlinked table.
################################################################################


#' Update Unlinked Table
#' 
#' Update the unlinked table by removing records that are already linked in the linked table.
#' 
#' @param conn A database connection.
#' 

updateUnlinked <- function(conn) {
  query <- paste(
    "DELETE a",
    "FROM unlinked a",
    "INNER JOIN",
    "(SELECT DISTINCT question_id, year from linked) b",
    "ON a.question_id = b.question_id AND a.year = b.year",
    "WHERE a.question_id = b.question_id"
  )
  DBI::dbExecute(conn, query)
}
