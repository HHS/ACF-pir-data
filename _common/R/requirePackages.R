requirePackages <- function(pkgs) {
  invisible(sapply(pkgs, require, character.only = T))
}