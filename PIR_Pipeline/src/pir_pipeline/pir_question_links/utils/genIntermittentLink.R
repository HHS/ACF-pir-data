################################################################################
## Written by: Reggie Gilliard
## Date: 01/02/2023
## Description: Script to generate intermittent links.
################################################################################


#' Generate Intermittent Link
#' 
#' This function generates an intermittent link between a base question and a linked question.
#' 
#' @param base_id The base question ID.
#' @param link_id The linked question ID.
#' @param data_conn A database connection object to the data source.
#' @param link_conn A database connection object to the linked table.
#' @return NULL
#' 
#' @details This function checks the uniqueness of the linked question, 
#' compares the counts of links associated with the linked question and the base question, 
#' and updates the "linked" table accordingly. If the linked question is unique 
#' and has more links than the base question, it updates the "linked" table with 
#' a new unique question ID. Otherwise, it inserts new records into the "linked" table 
#' with the base question ID. The function also logs the generated link.
#' 

genIntermittentLink <- function(base_id, link_id, data_conn, link_conn) {
  # Get column names from the "linked" table
  link_vars <- DBI::dbGetQuery(
    link_conn,
    paste(
      "SHOW COLUMNS",
      "FROM linked"
    )
  )$Field
  
  # Check the uniqueness of the linked question
  link_unique <- DBI::dbGetQuery(
    link_conn,
    paste(
      "SELECT COUNT(DISTINCT UQID)",
      "FROM linked",
      "WHERE question_id = ", paste0("'", link_id, "'")
    )
  )[[1]]
  
  # Count the number of links associated with the linked question
  count_link <- DBI::dbGetQuery(
    link_conn,
    paste(
      "SELECT COUNT(year)",
      "FROM linked",
      "WHERE uqid IN (", 
        paste(
          "SELECT DISTINCT uqid",
          "FROM linked",
          "WHERE question_id = ", paste0("'", link_id, "'")
        ),
      ")"
    )
  )[[1]]
  
  # Count the number of links associated with the base question
  count_base <- DBI::dbGetQuery(
    link_conn,
    paste(
      "SELECT COUNT(YEAR)",
      "FROM linked",
      "WHERE uqid = ", paste0("'", base_id, "'")
    )
  )[[1]]
  
  # Check conditions for generating an intermittent link
  if (link_unique == 1 & count_link > count_base) {
    new_id <- DBI::dbGetQuery(
      link_conn,
      paste(
        "SELECT DISTINCT uqid",
        "FROM linked",
        "WHERE question_id = ", paste0("'", link_id, "'")
      )
    )
  } else {
    new_id <- base_id
  }
  
  # Update "linked" table based on conditions
  if (count_link > 0 && count_base > 0) {
    
    if (count_link > count_base) {
      
      update_query <- paste0(
        "UPDATE linked ",
        "SET uqid = '", new_id, "' ",
        "WHERE uqid = '", base_id, "'"
      )
      
    } else {
      
      update_query <- paste0(
        "UPDATE linked ",
        "SET uqid = '", new_id, "' ",
        "WHERE question_id = '", link_id, "'"
      )
    
    }

    DBI::dbExecute(link_conn, update_query)
  
  
  } else {
    # Insert new records into "linked" table
    new_links <- DBI::dbGetQuery(
      data_conn,
      paste(
        "SELECT *",
        "FROM question",
        "WHERE question_id IN (", paste0("'", link_id, "'", collapse = ","), ")"
      )
    ) %>%
      mutate(uqid = new_id) %>%
      select(all_of(link_vars))

    replaceInto(link_conn, new_links, "linked")
    updateUnlinked(link_conn)
    
  }
  # Log the generated link
  logLink(base_id, link_id, "linked")
}