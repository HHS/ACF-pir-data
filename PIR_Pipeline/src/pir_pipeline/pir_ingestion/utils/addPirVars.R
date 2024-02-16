#' Add missing variables to a data frame
#' 
#' `addPirVars` is a function intended for use with assertr.
#' It will add variables in a vector, `mi_vars`, to the target
#' data frame.
#' 
#' @param list_of_errors Assertr list of errors.
#' @param data Data frame
#' @returns A data frame containing the variables in `mi_vars`.
#' @examples
#' mi_vars <- "chassis"
#' mtcars %>%
#'   assertr::verify(
#'     "chassis" %in% names(.),
#'     error_fun = addPirVars
#'   )

addPirVars <- function(list_of_errors, data) {
  for (v in mi_vars) {
    data[v] <- NA_character_
  }
  return(data)
}