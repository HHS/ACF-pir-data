pipeExpr <- function(data, expr, expr_env = NULL) {
  
  if (!is.null(expr_env)) {
    eval(expr, envir = expr_env)
  } else {
    eval(expr)
  }
  
  return(data)
}