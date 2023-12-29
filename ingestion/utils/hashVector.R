# Function to hash a string vector
hashVector <- function(string) {
  hashed <- future_map_chr(
    string,
    rlang::hash
  )
  return(hashed)
}