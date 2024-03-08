################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Pop the last element from a vector and return it.
################################################################################


#' Pop the last element from a vector and return it.
#' 
#' The `pop` function removes the last element from the input vector and returns it. 
#' It also updates the original vector in the calling environment if it exists.
#' 
#' @param vector The input vector from which to pop the last element.
#' @return The popped element.

pop <- function(vector) {
  # Capture the function call
  func_call <- match.call()
  # Extract the name of the vector
  name <- func_call$vector
  # Define the function's environment and parent environment
  func_env <- environment()
  func_parent_env <- parent.frame()
  # Remove the last element from the vector and store it
  output <- vector[length(vector)]
  popped <- vector[-length(vector)]
  # Check the length of the name
  name_len <- length(name)
  # Check if the vector exists in the parent environment
  if (name_len == 1) {
    existence_check <- exists(paste(name), envir = func_parent_env, inherits = F)
  } else {
    existence_check <- FALSE
  }
  # If the vector exists, update it in the parent environment
  if (name_len && existence_check) {
    assign(paste(name), popped, envir = func_parent_env)
  }
  # Return the popped element
  return(output)
}
