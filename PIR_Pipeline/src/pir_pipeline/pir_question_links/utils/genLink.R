#' Generate a link between two questions
#' 
#' `genLink` generates a link between two questions. It is primarily
#' for interactive in conjunction with Shiny.
#' @param base_id An unlinked question_id.
#' @param link_id A question_id to link `base_id` to.
#' @param conn A database connection.

genLink <- function(base_id, link_id, conn) {
  require(dplyr)
  
  unlinked_ids <- DBI::dbGetQuery(
    conn,
    "
    SELECT DISTINCT question_id
    FROM unlinked
    "
  )$question_id
  
  varnames <- DBI::dbGetQuery(
    conn,
    "
    SHOW COLUMNS
    FROM linked
    "
  )$Field
  
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
    
    unlinked <- filter(unlinked, question_id == base_id) %>%
      mutate(uqid = linked$uqid) %>%
      select(all_of(varnames))
    
  }
  
  replaceInto(conn, unlinked, "linked")
  updateUnlinked(conn)
  logLink(base_id, link_id, "linked")
}