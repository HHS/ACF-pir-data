dropNull <- function(list) {
  list[map_lgl(list, ~ !is.null(.))] %>%
    return()
}