################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Apply an expression using the pipe operator.
################################################################################


#' Apply an expression using the pipe operator.
#' 
#' The `pipeExpr` function applies the specified expression to the input data using the pipe operator (%>%). 
#' Optionally, it allows the user to specify an environment (`expr_env`) in which the expression should be evaluated.
#' 
#' @param data The input data to apply the expression to.
#' @param expr The expression to apply to the data.
#' @param expr_env An optional environment in which to evaluate the expression.
#' @return The input data after applying the expression.

pipeExpr <- function(data, expr, expr_env = NULL) {
  # Evaluate the expression in the specified environment (if provided)
  if (!is.null(expr_env)) {
    eval(expr, envir = expr_env)
  } else {
    eval(expr)
  }
  # Return the modified data
  return(data)
}