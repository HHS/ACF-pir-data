################################################################################
## Written by: Reggie Gilliard
## Date: 01/02/2023
## Description: Script to delete question links
################################################################################


#' Delete Link
#' 
#' This function deletes a link between a unique question ID (uqid) and one or more question IDs.
#' 
#' @param conn A database connection object.
#' @param uqid Unique question ID to delete link from.
#' @param question_id_list A list of question IDs to be unlinked.
#' @return NULL
#' 
#' @details This function deletes the link between the specified uqid and question IDs, 
#' moves the affected records to the "unlinked" table temporarily, deletes the target records, 
#' removes any records in "unlinked" that are still present in the "linked" table, 
#' logs the deleted links, and updates the "unlinked" table.
#' 
#' @assertion The number of unique questions in newly_unlinked should be the same as 
#' the number of questions in question_id_list.
#' 

deleteLink <- function(conn, uqid, question_id_list) {
  #' ADD ASSERTION HERE THAT THE NUMBER OF UNIQUE QUESTIONS IN newly_unlinked
  #' IS THE SAME AS THE NUMBER OF QUESTIONS IN question_id_list
  
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
  newly_unlinked <- DBI::dbGetQuery(
    conn,
    unlinked_query
  )
  # Move all affected records to unlinked temporarily
  replaceInto(conn, newly_unlinked, "unlinked")
  # Delete target records
  DBI::dbExecute(conn, delete_query)
  # Remove any records in unlinked that are actually still present in the linked table
  updateUnlinked(conn)
  purrr::map(
    question_id_list,
    function(id) {
      logLink(uqid, id, "unlinked")
    }
  )
}