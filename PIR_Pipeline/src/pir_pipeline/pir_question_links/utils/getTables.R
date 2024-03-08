################################################################################
## Written by: Reggie Gilliard
## Date: 01/02/2023
## Description: Script to get database tables.
################################################################################


#' Get Database Tables and Variables
#' 
#' This function retrieves the tables and their variables from the provided
#' database connections.
#' 
#' @param question_conn A database connection object for questions.
#' @param link_conn A database connection object for links.
#' @param lower_year The lower year boundary for filtering questions.
#' @return A list containing the following components:
#'   \itemize{
#'     \item{"linked_db"}{A data frame of distinct uqid and matching variables from linked table.}
#'     \item{"unlinked_db"}{A data frame of distinct variables from unlinked table.}
#'     \item{"lower_year"}{A data frame of questions from the lower year boundary.}
#'     \item{"question_vars"}{A character vector of variable names in the questions table.}
#'     \item{"linked_vars"}{A character vector of variable names in the linked table.}
#'     \item{"unlinked_vars"}{A character vector of variable names in the unlinked table.}
#'   }
#' 

getTables <- function(question_conn, link_conn, lower_year) {
  pkgs <- c("dplyr", "purrr")
  invisible(sapply(pkgs, require, character.only = T))
  
  # Retrieve matching variables from linked table
  matching_vars <- dbGetQuery(
    link_conn,
    paste(
      "SHOW COLUMNS",
      "FROM linked",
      "WHERE Field like 'question%' OR Field IN ('section', 'year')"
    )
  )
  matching_vars <- paste(matching_vars$Field, collapse = ",")
  
  # Retrieve variables for linked and unlinked tables
  table_vars <- map(
    c("linked", "unlinked"),
    function(table) {
      dbGetQuery(
        link_conn,
        paste(
          "SHOW COLUMNS",
          "FROM", table
        )
      )
    }
  )
  
  # Retrieve distinct data from linked table
  linked_db <- dbGetQuery(
    link_conn,
    paste(
      "SELECT DISTINCT uqid,", matching_vars,
      "FROM linked"
    )
  )
  
  # Retrieve distinct data from unlinked table
  unlinked_db <- dbGetQuery(
    link_conn,
    paste(
      "SELECT DISTINCT *",
      "FROM unlinked"
    )
  ) %>%
    select(-proposed_link)
  
  # Retrieve questions for the lower year boundary
  question_frames <- map(
    c(lower_year),
    function(yr) {
      dbGetQuery(
        question_conn,
        paste(
          "SELECT *",
          "FROM question",
          "WHERE year =", yr
        )
      ) %>%
        mutate(
          across(
            starts_with("question"),
            ~ ifelse(is.na(.), "", .)
          )
        ) %>%
        return()
    }
  )
  
  # Return the collected data
  return(
    list(
      "linked_db" = linked_db, 
      "unlinked_db" = unlinked_db,
      "lower_year" = question_frames[[1]], 
      # "upper_year" = question_frames[[2]],
      "question_vars" = names(question_frames[[1]]),
      "linked_vars" = table_vars[[1]]$Field,
      "unlinked_vars" = table_vars[[2]]$Field
    )
  )
}
