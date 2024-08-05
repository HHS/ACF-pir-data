################################################################################
## Written by: Reggie Gilliard
## Date: 02/23/2024
## Description: Define a function to remove NULL elements from a list.
################################################################################


#' Remove NULL elements from a list.
#' 
#' The `dropNull` function removes NULL elements from a given list.
#' It returns a modified list without any NULL elements.
#' 
#' @param list The input list.
#' @return The modified list with NULL elements removed.

dropNull <- function(list) {
  # Filter out NULL elements from the list using purrr::map_lgl
  list[purrr::map_lgl(list, ~ !is.null(.))] %>%
    # Return the filtered list
    return()
}