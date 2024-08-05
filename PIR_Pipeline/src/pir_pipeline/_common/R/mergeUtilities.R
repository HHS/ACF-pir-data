################################################################################
## Written by: Mathematica
## Date: 02/23/2024
## Description: Define functions for dataframe joins.
################################################################################


# Load the dplyr package
require(dplyr)

# Define the `%notin%` operator to check for absence in a set
`%notin%` <- Negate(`%in%`)


#' Merge two data frames with check for successful merging.
#' 
#' The `merge_check` function is an auxiliary function used to check 
#' the merging status of two data frames. It assigns a merge status 
#' based on the merge flags `merge.x` and `merge.y`.
#' 
#' @param df The data frame resulting from a merge operation.
#' @return The modified data frame with the merge status column added.

merge_check <- function(df) {
  # Perform merging status check and assign merge status
  df %>%
    mutate(
      merge = case_when(
        merge.x == 1 & merge.y == 1 ~ 3,
        merge.x == 1 & is.na(merge.y) ~ 1,
        is.na(merge.x) & merge.y == 1 ~ 2
      )
    ) %>%
    # Remove merge.x and merge.y columns
    select(-c("merge.x", "merge.y"))
  
}


#' Perform a full join with check for successful merging.
#' 
#' The `full_join_check` function performs a full join between two data frames 
#' and checks for successful merging using the `merge_check` function.
#' 
#' @param x First data frame to join.
#' @param y Second data frame to join.
#' @param by Variables to join by (defaults to NULL).
#' @param tab Logical indicating whether to generate a table (defaults to FALSE).
#' @param verify Numeric vector specifying the expected merge results (defaults to NULL).
#' @return The merged data frame with merge status column added.

full_join_check <- function(x, y, by = NULL, tab = F, verify = NULL, ...) {
  # Perform full join and check merging status
  df <- full_join(
    mutate(x, merge = 1), 
    mutate(y, merge = 1), 
    by = by, ...
  ) %>%
    merge_check()
  
  # if (tab == T) {
  #   df %>%
  #     tablist(merge)
  # }
  
  # Check for specified merge results
  if (!is.null(verify)) {
    if (all(is.character(verify))) {
      warning('verify must be numeric')
    } else if (all(verify %notin% c(1, 2, 3))) {
      warning('verify uses stata syntax: 1 = master, 2 = using, 3 = merged')
    }
    
    stopifnot(all(unique(df$merge) %in% c(verify)))
  }
  
  return(df)
  
}


#' Perform an inner join with check for successful merging.
#' 
#' The `inner_join_check` function performs an inner join between two data frames 
#' and checks for successful merging using the `full_join_check` function.
#' 
#' @param x First data frame to join.
#' @param y Second data frame to join.
#' @param by Variables to join by (defaults to NULL).
#' @param tab Logical indicating whether to generate a table (defaults to FALSE).
#' @param verify Numeric vector specifying the expected merge results (defaults to NULL).
#' @return The merged data frame with merge status column added.

inner_join_check <- function(x, y, by = NULL, tab = F, verify = NULL, ...) {
  # Perform inner join and filter based on successful merge
  df <- full_join_check(x, y, by, tab = tab, verify = verify, ...) %>%
    filter(merge == 3)
  
  return(df)
  
}


#' Perform a left join with check for successful merging.
#' 
#' The `left_join_check` function performs a left join between two data frames 
#' and checks for successful merging using the `full_join_check` function.
#' 
#' @param x First data frame to join.
#' @param y Second data frame to join.
#' @param by Variables to join by (defaults to NULL).
#' @param tab Logical indicating whether to generate a table (defaults to FALSE).
#' @param verify Numeric vector specifying the expected merge results (defaults to NULL).
#' @return The merged data frame with merge status column added.

left_join_check <- function(x, y, by = NULL, tab = F, verify = NULL, ...) {
  # Perform left join and filter based on successful merge
  df <- full_join_check(x, y, by, tab = tab, verify = verify, ...) %>%
    filter(merge %in% c(1, 3))
  
  return(df)
  
}


#' Perform a right join with check for successful merging.
#' 
#' The `right_join_check` function performs a right join between two data frames 
#' and checks for successful merging using the `full_join_check` function.
#' 
#' @param x First data frame to join.
#' @param y Second data frame to join.
#' @param by Variables to join by (defaults to NULL).
#' @param tab Logical indicating whether to generate a table (defaults to FALSE).
#' @param verify Numeric vector specifying the expected merge results (defaults to NULL).
#' @return The merged data frame with merge status column added.

right_join_check <- function(x, y, by = NULL, tab = F, verify = NULL, ...) {
  # Perform right join and filter based on successful merge
  df <- full_join_check(x, y, by, tab = tab, verify = verify, ...) %>%
    filter(merge %in% c(2, 3))
  
  return(df)
  
}

