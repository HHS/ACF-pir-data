################################################################################
## Written by: Reggie Gilliard
## Date: 05/08/2024
## Description: Update the unlinked table.
################################################################################


#' Update Linked Table
#' 
#' Update the Linked table by uqids that appear only once.
#' 
#' @param conn A database connection.
#' @param uqid Unique question ID to check

updateLinked <- function(conn, uqid) {
    distinct_uqid <- paste(
        "SELECT year, question_id, question_name, question_text, question_number, category, section",
        "FROM linked",
        "WHERE uqid =", paste0("'", uqid, "'")
    )
    distinct_uqid <- DBI::dbGetQuery(
        conn,
        distinct_uqid
    )
    if (nrow(distinct_uqid) == 1) {
        distinct_qid <- paste(
            "SELECT count(question_id)",
            "FROM linked",
            "WHERE uqid =", paste0("'", uqid, "'")
        )
        distinct_qid <- DBI::dbGetQuery(
            conn,
            distinct_qid
        )
        if (distinct_qid == 1) {
            replaceInto(conn, distinct_uqid, "unlinked")
        }
        delete_query <- paste(
            "DELETE FROM linked",
            "WHERE uqid =", paste0("'", uqid, "'")
        )
        DBI::dbExecute(conn, delete_query)
    }
}