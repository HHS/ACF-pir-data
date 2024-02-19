moveFiles <- function(path_list, destination) {
  require(purrr)
  map(
    path_list,
    function(path) {
      if (!dir.exists(destination)) {
        dir.create(destination, recursive = TRUE)
      }
      fname <- gsub(".*(?<=\\\\|\\/)([\\w\\-\\.]+)$", "\\1", path_list, perl = T)
      today <- format(Sys.Date(), "%Y%m%d")
      fname <- paste0(
        gsub("^(.+)\\.\\w+$", "\\1", fname),
        "_",
        today,
        gsub("^.+(\\.\\w+)$", "\\1", fname)
      )
      destination <- file.path(destination, fname)
      file.copy(path, destination)
      # file.remove(path)
    }
  )
}
