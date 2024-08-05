################################################################################
## Written by: Reggie Gilliard
## Date: 02/10/2024
## Description: Define a function to move files from raw to processed, 
## scheduled, or unprocessed folders.
################################################################################


#' Move files to a specified folder.
#' 
#' The `moveFiles` function moves files specified in the `path_list` to the `destination` directory. 
#' It creates the destination directory if it does not exist and renames the files with a timestamp 
#' suffix to avoid overwriting existing files.
#' 
#' @param path_list A character vector containing paths of the files to be moved.
#' @param destination The destination directory where files will be moved.
#' @return NULL

moveFiles <- function(path_list, destination) {
  # Load the purrr package
  require(purrr)
  # Iterate through each path in the list
  map(
    path_list,
    function(path) {
      # Create the destination directory if it doesn't exist
      if (!dir.exists(destination)) {
        dir.create(destination, recursive = TRUE)
      }
      # Extract the filename from the path and append timestamp suffix
      fname <- gsub(".*(?<=\\\\|\\/)([\\w\\-\\.]+)$", "\\1", path_list, perl = T)
      today <- format(Sys.Date(), "%Y%m%d")
      fname <- paste0(
        gsub("^(.+)\\.\\w+$", "\\1", fname),
        "_",
        today,
        gsub("^.+(\\.\\w+)$", "\\1", fname)
      )
      # Define the destination path for the file
      destination <- file.path(destination, fname)
      # Copy the file to the destination and remove the original file
      file.copy(path, destination)
      file.remove(path)
    }
  )
}
