addUnmatched <- function(data) {
  if ("unmatched" %notin% names(data)) {
    data <- mutate(data, unmatched = NA_character_)
  }
  return(data)
}