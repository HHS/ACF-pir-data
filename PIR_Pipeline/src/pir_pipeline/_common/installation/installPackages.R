# Packages
args <- commandArgs(TRUE)
renv_path <- args[1]

source(file.path(renv_path, "activate.R"))
renv::restore()