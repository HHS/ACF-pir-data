pop <- function(vector) {
  func_call <- match.call()
  name <- func_call$vector
  func_env <- environment()
  func_parent_env <- parent.frame()
  
  output <- vector[length(vector)]
  popped <- vector[-length(vector)]
  
  name_len <- length(name)

  if (name_len == 1) {
    existence_check <- exists(paste(name), envir = func_parent_env, inherits = F)
  } else {
    existence_check <- FALSE
  }
  if (name_len && existence_check) {
    assign(paste(name), popped, envir = func_parent_env)
  }
  return(output)
}
