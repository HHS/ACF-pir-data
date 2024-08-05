################################################################################
## Written by: Reggie Gilliard
## Date: 01/02/2023
## Description: Script to generate a link between two questions.
################################################################################


#' Generate a link between two questions
#' 
#' `genLink` generates a link between two questions. It is primarily
#' for interactive in conjunction with Shiny.
#' @param base_id An unlinked question_id.
#' @param link_id A question_id to link `base_id` to.
#' @param conn A database connection.

genLink <- function(base_id, link_id, conn) {
  require(dplyr)
  
  # Retrieve distinct unlinked question IDs
  unlinked_ids <- DBI::dbGetQuery(
    conn,
    "
    SELECT DISTINCT question_id
    FROM unlinked
    "
  )$question_id
  
  # Retrieve column names from the "linked" table
  varnames <- DBI::dbGetQuery(
    conn,
    "
    SHOW COLUMNS
    FROM linked
    "
  )$Field
  
  # Retrieve information about unlinked questions
  unlinked <- DBI::dbGetQuery(
    conn,
    paste0(
      "
      SELECT *
      FROM unlinked
      WHERE question_id IN (
      '", link_id, "','", base_id, "')"
    )
  )
  
  # If neither question was linked
  if (link_id %in% unlinked_ids) {
    
    unlinked <- unlinked %>%
      mutate(
        uqid = uuid::UUIDgenerate()
      ) %>%
      select(all_of(varnames))
    
  } else {
    linked <- DBI::dbGetQuery(
      conn,
      paste0(
        "
        SELECT DISTINCT uqid
        FROM linked
        WHERE question_id = '", link_id, "'"
      )
    )
    # Update the unlinked question's record with the associated UQID
    unlinked <- filter(unlinked, question_id == base_id) %>%
      mutate(uqid = linked$uqid) %>%
      select(all_of(varnames))
    
  }
  # Insert or update records in the "linked" table
  replaceInto(conn, unlinked, "linked")
  updateUnlinked(conn)
  logLink(base_id, link_id, "linked")
}