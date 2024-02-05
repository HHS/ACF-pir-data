deleteLink <- function(conn, uqid, question_id_list) {
  delete_query <- paste(
    "DELETE FROM linked",
    "WHERE uqid =", paste0("'", uqid, "'"), "AND", "question_id IN (",
      paste0("'", question_id_list, "'", collapse = ", "),
    ")"
  )
  unlinked_query <- paste(
    "SELECT year, question_id, question_name, question_text, question_number, category, section",
    "FROM linked",
    "WHERE uqid =", paste0("'", uqid, "'"), "AND", "question_id IN (",
      paste0("'", question_id_list, "'", collapse = ", "),
    ")"
  )
  newly_unlinked <- dbGetQuery(
    conn,
    unlinked_query
  )
  # Move all affected records to unlinked temporarily
  replaceInto(conn, newly_unlinked, "unlinked")
  # Delete target records
  dbExecute(conn, delete_query)
  # Remove any records in unlinked that are actually still present in the linked table
  updateUnlinked(conn)
  map(
    question_id_list,
    function(id) {
      logLink(uqid, id, "unlinked")
    }
  )
}