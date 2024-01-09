addPirVars <- function(list_of_errors, data) {
  for (v in mi_vars) {
    data[v] <- NA_character_
  }
  return(data)
}