cleanQuestions <- function(df_list) {
  pkgs <- c("uuid", "assertr", "stringr", "rlang", "jsonlite", "tidyr", "dplyr")
  invisible(sapply(pkgs, require, character.only = T))
  
  linked_vars <- df_list$linked_vars
  unlinked_vars <- df_list$unlinked_vars
  unlinked <- df_list$unlinked
  linked <- df_list$linked
  
  # Separate data
  if (nrow(linked) > 0) {
    linked <- linked %>%
      select(
        matches(linked_vars), -matches(c("dist", "subsection"))
      )
    df_list$linked <- linked
  }
  
  if (nrow(unlinked) > 0) {
    unlinked <- unlinked %>%
      select(
        matches(unlinked_vars), -matches(c("dist", "subsection"))
      )
    
    df_list$unlinked <- unlinked
    
  }
  
  # if (nrow(df_list$linked_db) > 0) {
  # 
  #   new_row_count <- sum(nrow(linked), nrow(unlinked), na.rm = T)
  #   orig_row_count <- nrow(df_list$lower_year)
  #   
  #   if (new_row_count != orig_row_count) {
  #     if (new_row_count > orig_row_count) {
  #       stop("Too many variables")
  #     } else {
  #       stop("Too few variables")
  #     }
  #   }
  # 
  # }
  
  return(df_list)
}

