################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Load required packages.
################################################################################


#' Load required packages.
#' 
#' The `requirePackages` function loads the specified packages (`pkgs`) into the R session. 
#' It is a wrapper around the `require` function, ensuring that packages are loaded silently.
#' 
#' @param pkgs A character vector specifying the names of the packages to be loaded.
#' @return NULL

requirePackages <- function(pkgs) {
  invisible(sapply(pkgs, require, character.only = T))
}