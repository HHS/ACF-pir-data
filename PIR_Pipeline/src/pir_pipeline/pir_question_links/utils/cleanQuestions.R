#' Prepare questions for insertion into question_links database
#' 
#' `cleanQuestions` performs cleaning and data integrity checks on linked and
#' unlinked records.
#' @param df_list A list returned from `checkUnlinked()`.
#' @returns A list of data frames ready for insertion.

cleanQuestions <- function(df_list) {
  require(dplyr)
  
  # Extract data
  linked_vars <- df_list$linked_vars
  unlinked_vars <- df_list$unlinked_vars
  unlinked <- df_list$unlinked
  linked <- df_list$linked
  lower <- df_list$lower_year
  
  # Separate data
  if (!is.null(linked)) {
    linked <- linked %>%
      select(
        matches(linked_vars), -matches(c("dist", "subsection"))
      )
    df_list$linked <- linked
  }
  
  if (!is.null(unlinked)) {
    unlinked <- unlinked %>%
      select(
        matches(unlinked_vars), -matches(c("dist", "subsection"))
      )
    
    df_list$unlinked <- unlinked
    
  }
  
  # Data Integrity checks ----
  
  # Ensure that there are no proposed links within a given year.
  # i.e. question A.1 from 2023 cannot be proposed to link with question
  # A.2 from 2023.
  if (!is.null(unlinked) && nrow(unlinked) > 0) {
    proposed_link_ids <- purrr::map(
      purrr::map(
        unlinked$proposed_link,
        jsonlite::fromJSON
      ),
      names
    )
    proposed_link_ids <- unlist(proposed_link_ids)
    problematic <- setdiff(
      proposed_link_ids, 
      c(linked$question_id, df_list$linked_db$question_id)
    )
    overlap <- intersect(unlinked$question_id, problematic)
    if (length(overlap) != 0) {
      stop("Proposed links within year!")
    }
  }
  
  # The number of rows in linked and unlinked from the current year
  # must sum to the number of rows in the current year's question data
  if (!is.null(linked)) {
    linked_rows <- filter(linked, year == unique(lower$year)) %>%
      distinct(question_id) %>%
      nrow()
  } else {
    linked_rows <- 0
  }
  
  if (!is.null(unlinked)) {
    unlinked_rows <- filter(unlinked, year == unique(lower$year)) %>%
      distinct(question_id) %>%
      nrow()
  } else {
    unlinked_rows <- 0
  }
  
  new_row_count <- sum(
    linked_rows,
    unlinked_rows,
    na.rm = T
  )
  
  orig_row_count <- nrow(df_list$lower_year)
  
  if (new_row_count != orig_row_count) {
    if (new_row_count > orig_row_count) {
      stop("Too many variables")
    } else {
      stop("Too few variables")
    }
  }
  
  # The sum of the records in the linked and unlinked data must be
  # less than or equal to the sum of the number of rows in the current
  # year's question data and the number of rows in the unlinked database.
  new_row_count <- sum(nrow(linked), nrow(unlinked), na.rm = T)
  orig_row_count <- sum(nrow(df_list$lower_year), nrow(df_list$unlinked_db))

  if (new_row_count > orig_row_count) {
    stop("Too many variables")
  }
  
  return(df_list)
}

