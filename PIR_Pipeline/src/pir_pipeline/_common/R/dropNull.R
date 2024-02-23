dropNull <- function(list) {
  list[purrr::map_lgl(list, ~ !is.null(.))] %>%
    return()
}