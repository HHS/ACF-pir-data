genIntermittentLink <- function(base_id, link_id, data_conn, link_conn) {
  link_vars <- DBI::dbGetQuery(
    link_conn,
    paste(
      "SHOW COLUMNS",
      "FROM linked"
    )
  )$Field
  
  link_unique <- DBI::dbGetQuery(
    link_conn,
    paste(
      "SELECT COUNT(DISTINCT UQID)",
      "FROM linked",
      "WHERE question_id = ", paste0("'", link_id, "'")
    )
  )[[1]]
  
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
  
  count_base <- DBI::dbGetQuery(
    link_conn,
    paste(
      "SELECT COUNT(YEAR)",
      "FROM linked",
      "WHERE uqid = ", paste0("'", base_id, "'")
    )
  )[[1]]
  
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
  
  if (count_link > 0 && count_base > 0) {
  
    update_query <- paste0(
      "UPDATE linked ",
      "SET uqid = '", new_id, "' ",
      "WHERE question_id = '", link_id, "'"
    )
    DBI::dbExecute(link_conn, update_query)
  
  
  } else {
    
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
  logLink(base_id, link_id, "linked")
}