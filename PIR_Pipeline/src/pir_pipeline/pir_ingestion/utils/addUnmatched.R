################################################################################
## Written by: Reggie Gilliard
## Date: 11/10/2023
## Description: Add unmatched variables to a data frame
################################################################################


#' Add the variable `unmatched` to a data frame
#' 
#' @param data Data frame
#' @returns A data frame containing the variable `unmatched`.
#' @examples
#' addUnmatched(mtcars)

addUnmatched <- function(data) {
  if ("unmatched" %notin% names(data)) {
    data <- dplyr::mutate(data, unmatched = NA_character_)
  }
  return(data)
}