questionLinks2011 <- function(conn) {

  unlinked <- dbGetQuery(
    conn,
    "
    SELECT *
    FROM unlinked
    WHERE year = 2011
    "
  )
  
  linked <- dbGetQuery(
    conn,
    "
    SELECT DISTINCT uqid, question_number
    FROM linked
    WHERE question_number LIKE 'B.5.%' AND year < 2011 and year >= 2008
    "
  )
  
  link_vars <- dbGetQuery(
    conn,
    "
    SHOW COLUMNS FROM linked
    "
  )[[1]]
  
  if (nrow(unlinked) > 0 && nrow(linked) > 0) {
    
    # Recode B.8. variables
    unlinked <- unlinked %>%
      mutate(
        question_number_revised = case_when(
          grepl("^B\\.8\\.d\\.2", question_number) ~ gsub("^(B\\.8\\.d\\.2)(.*)", "B\\.5\\.d\\.1\\2", question_number),
          grepl("^B\\.8\\.d\\.3", question_number) ~ gsub("^(B\\.8\\.d\\.3)(.*)", "B\\.5\\.d\\.2\\2", question_number),
          grepl("^B\\.5\\.d\\.3", question_number) ~ gsub("^(B\\.5\\.d\\.3)(.*)", "B\\.5\\.d\\.2\\2", question_number),
          grepl("^B\\.[85]\\.d\\.\\d\\-", question_number) ~ question_number,
          grepl("^B\\.8\\.b\\.3", question_number) ~ gsub("^(B\\.8\\.b\\.3)(.*)", "B\\.5\\.b\\.4\\2", question_number),
          grepl("^(B\\.8\\.)(.*)", question_number) ~ gsub("^(B\\.8\\.)(.*)$", "B\\.5\\.\\2", question_number, perl = TRUE),
          TRUE ~ question_number
        )
      )
    
    linked <- inner_join(
      unlinked,
      linked,
      by = c("question_number_revised" = "question_number")
    ) %>%
      select(all_of(link_vars))
    
    pmap(
      linked[, c("uqid", "question_id")],
      function(uqid, question_id) {
        logLink(uqid, question_id, "linked")
      }
    )
    replaceInto(conn, linked, "linked")
    updateUnlinked(conn)
  }
}