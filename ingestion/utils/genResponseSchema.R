genResponseSchema <- function(conn, year) {
  query <- paste(
    paste0("CREATE TABLE IF NOT EXISTS response", year), "(",
    "`uid` varchar(255),",
    "`question_id` varchar(255),",
    "`answer` TEXT,",
    "`year` YEAR,",
    "PRIMARY KEY (`uid`, `question_id`)",
    ")"
  )
  dbExecute(conn, query)
}
