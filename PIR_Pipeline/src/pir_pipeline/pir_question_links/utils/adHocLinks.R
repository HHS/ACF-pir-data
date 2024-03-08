################################################################################
## Written by: Reggie Gilliard
## Date: 01/09/2023
## Description: This script handles the creation of ad hoc links in the database.
################################################################################


#' Ad Hoc Links
#' 
#' This function handles the creation of ad hoc links in the database.
#' 
#' @param conn A database connection object.
#' @return NULL
#' 
#' @details This function retrieves unlinked and linked data from the database, creates ad hoc links 
#' according to specified criteria, logs the created links, and updates the database with the new links.
#' 

adHocLinks <- function(conn) {
  # Load the dplyr package for data manipulation
  require(dplyr)
  
  # Ad Hoc Links - 2011
  unlinked <- DBI::dbGetQuery(
    # Retrieve unlinked data for the year 2011
    conn,
    "
    SELECT *
    FROM unlinked
    WHERE year = 2011
    "
  )
  
  linked <- DBI::dbGetQuery(
    conn,
    "
    SELECT DISTINCT uqid, question_number
    FROM linked
    WHERE question_number LIKE 'B.5%' AND year < 2011 and year >= 2008
    "
  )
  
  link_vars <- DBI::dbGetQuery(
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
          grepl("^B\\.8\\.d\\.2", question_number) ~ gsub("^(B\\.8\\.d\\.2)(.*)", "B\\.5\\.d\\.1\\2", question_number, perl = TRUE),
          grepl("^B\\.8\\.d\\.3", question_number) ~ gsub("^(B\\.8\\.d\\.3)(.*)", "B\\.5\\.d\\.2\\2", question_number, perl = TRUE),
          grepl("^B\\.5\\.d\\.3", question_number) ~ gsub("^(B\\.5\\.d\\.3)(.*)", "B\\.5\\.d\\.2\\2", question_number, perl = TRUE),
          grepl("^B\\.[85]\\.d\\.\\d\\-", question_number) ~ question_number,
          grepl("^B\\.8\\.b\\.3", question_number) ~ gsub("^(B\\.8\\.b\\.3)(.*)", "B\\.5\\.b\\.4\\2", question_number, perl = TRUE),
          grepl("^B\\.8\\-\\d$", question_number) ~ gsub("^(B\\.8)(\\-\\d)$", "B\\.5\\2", question_number, perl = TRUE),
          grepl("^(B\\.8\\.)(.*)", question_number) ~ gsub("^(B\\.8\\.)(.*)$", "B\\.5\\.\\2", question_number, perl = TRUE),
          TRUE ~ question_number
        )
      )
    
    linked <- inner_join(
      unlinked,
      linked,
      by = c("question_number_revised" = "question_number"),
      # Perform an inner join to link the data based on specified columns
      relationship = "many-to-one"
    ) %>%
      select(all_of(link_vars))
    # Log and update links
    pmap(
      linked[, c("uqid", "question_id")],
      function(uqid, question_id) {
        # Log the link
        logLink(uqid, question_id, "linked")
      }
    )
    # Replace existing data in the "linked" table
    replaceInto(conn, linked, "linked")
    # Update the "unlinked" table
    updateUnlinked(conn)
  }
  
  # Ad Hoc Links - 2023
  unlinked <- DBI::dbGetQuery(
    conn,
    "
    SELECT *
    FROM unlinked
    WHERE year = 2023
    "
  )
  
  linked <- DBI::dbGetQuery(
    conn,
    "
    SELECT DISTINCT uqid, question_number
    FROM linked
    WHERE year < 2023 and year >= 2021
    "
  )
  
  if (nrow(unlinked) > 0 && nrow(linked) > 0) {
    
    # Recode
    unlinked <- unlinked %>%
      mutate(
        question_number_revised = case_when(
          grepl("C\\.8\\.b", question_number) ~ gsub("^(C\\.8\\.b)(.*)", "C\\.7\\.b\\2", question_number, perl = T),
          grepl("C\\.19", question_number) ~ gsub("^(C\\.19)(.*)", "C\\.18\\2", question_number, perl = T),
          grepl("C\\.20", question_number) ~ gsub("^(C\\.20)(.*)", "C\\.19\\2", question_number, perl = T),
          grepl("C\\.38", question_number) ~ gsub("^(C\\.38)(.*)", "C\\.37\\2", question_number, perl = T),
          grepl("C\\.31", question_number) ~ gsub("^(C\\.31)(.*)", "C\\.30\\2", question_number, perl = T),
          TRUE ~ question_number
        )
      )
    
    linked <- linked %>%
      mutate(
        question_number_revised = case_when(
          grepl("^B\\.13\\.h\\.\\d$", question_number) ~ "B.13.h",
          TRUE ~ question_number
        )
      ) %>%
      # Exclude the original question_number column
      select(-c(question_number))
    
    linked <- inner_join(
      unlinked,
      linked,
      by = c("question_number_revised" = "question_number_revised"),
      # Perform an inner join to link the data based on specified columns
      relationship = "one-to-many"
    ) %>%
      select(all_of(link_vars))
    
    pmap(
      linked[, c("uqid", "question_id")],
      function(uqid, question_id) {
        logLink(question_id, uqid, "linked")
      }
    )
    
    replaceInto(conn, linked, "linked")
    updateUnlinked(conn)
  }
  
  # Other Ad-hoc links
  unlinked <- DBI::dbGetQuery(
    conn,
    "
    SELECT * 
    FROM unlinked
    "
  )
  
  linked <- DBI::dbGetQuery(
    conn,
    "
    SELECT DISTINCT uqid, question_id
    FROM linked
    "
  )
  
  if (nrow(unlinked) > 0 && nrow(linked) > 0) {
    
    ad_hoc_links <- readRDS(here("pir_question_links", "utils", "ad_hoc_links.RDS"))
    
    unlinked <- inner_join(
      unlinked,
      ad_hoc_links,
      by = "question_id"
    )
    
    linked <- inner_join(
      unlinked,
      linked,
      by = c("link_id" = "question_id")
    ) %>%
      select(all_of(link_vars))
    
    pmap(
      linked[, c("uqid", "question_id")],
      function(uqid, question_id) {
        logLink(question_id, uqid, "linked")
      }
    )
    
    replaceInto(conn, linked, "linked")
    updateUnlinked(conn)
  }
  
}