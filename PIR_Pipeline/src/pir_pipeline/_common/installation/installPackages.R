# Packages
args <- commandArgs(TRUE)
library_path <- args[1]

if (!requireNamespace("renv", quietly = TRUE)) {
    if (!dir.exists(library_path)) {
        dir.create(library_path, recursive = TRUE)
        .libPaths(c(.libPaths(), library_path))
    }
    install.packages("renv", lib = library_path, repos = "https://cloud.r-project.org/", prompt = FALSE)
    library(renv, lib = library_path)
}

renv::restore()