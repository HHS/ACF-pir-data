# Function to hash a string vector
hashVector <- function(string) {
  pkgs <- c("furrr", "digest")
  invisible(sapply(pkgs, require, character.only = T))
  
  hashed <- future_map_chr(
    string,
    function(s) {
      digest(s, algo = "md5", serialize = F)
    }
  )
  return(hashed)
}