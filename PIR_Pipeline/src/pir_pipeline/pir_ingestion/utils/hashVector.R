################################################################################
## Written by: Reggie Gilliard
## Date: 11/10/2023
## Description: Return a hash for each element of a string vector/list of strings
################################################################################


#' Return a hash for each element of a string vector/list of strings
#' 
#' `hasVector` returns a vector of md5 hashes the of the same length
#' as the provided vector of strings
#' 
#' @param string A string, or vector of strings, to be hashed.
#' @returns A hased string or vector of hashed strings.

hashVector <- function(string) {
  
  hashed <- purrr::map_chr(
    string,
    function(s) {
      digest::digest(s, algo = "md5", serialize = F)
    }
  )
  return(hashed)
}