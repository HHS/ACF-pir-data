cleanQuestions <- function(df_list) {
  pkgs <- c("uuid", "assertr", "stringr", "rlang", "jsonlite", "tidyr", "dplyr")
  invisible(sapply(pkgs, require, character.only = T))
  
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
  
  # Data Integrity checks
  if (!is.null(unlinked) && nrow(unlinked) > 0) {
    proposed_link_ids <- map(
      map(
        unlinked$proposed_link,
        fromJSON
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
  
  new_row_count <- sum(nrow(linked), nrow(unlinked), na.rm = T)
  orig_row_count <- sum(nrow(df_list$lower_year), nrow(df_list$unlinked_db))

  if (new_row_count > orig_row_count) {
    stop("Too many variables")
  }
  
  return(df_list)
}

