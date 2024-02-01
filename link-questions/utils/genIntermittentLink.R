genIntermittentLink <- function(base_id, link_id, data_conn, link_conn, type) {
  if (type == "intermittent") {
    link_vars <- dbGetQuery(
      link_conn,
      paste(
        "SHOW COLUMNS",
        "FROM linked"
      )
    )$Field
    
    new_links <- dbGetQuery(
      data_conn,
      paste(
        "SELECT *",
        "FROM question",
        "WHERE question_id IN (", paste0("'", link_id, "'", collapse = ","), ")"
      )
    ) %>%
      mutate(uqid = base_id) %>%
      select(all_of(link_vars))
    
    replaceInto(link_conn, new_links, "linked")
    updateUnlinked(link_conn)
  }
}
