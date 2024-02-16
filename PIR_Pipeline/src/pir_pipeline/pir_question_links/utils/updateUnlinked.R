updateUnlinked <- function(conn) {
  query <- paste(
    "DELETE a",
    "FROM unlinked a",
    "INNER JOIN",
    "(select distinct question_id, year from linked) b",
    "ON a.question_id = b.question_id AND a.year = b.year",
    "WHERE a.question_id = b.question_id"
  )
  DBI::dbExecute(conn, query)
}
