###################################################
##  Created by: Polina Polskaia
##  Description: Takes information from watcher and schedules the ingestion
##
###################################################

# Setup ----

# Remove all objects from the workspace
rm(list = ls())


# TODO:: Delete?
# Set directory 
# setwd("C:\\OHS-Project-1\\ACF-pir-data\\") 
# .libPaths("C:/Users/Administrator/AppData/Local/R/win-library/4.3")


# Load required libraries
pkgs <- c(
  "here", "dplyr", "RMariaDB"
)

invisible(
  lapply(
    pkgs,
    function(pkg) {
      if (!requireNamespace(pkg, quietly = TRUE)) {
        renv::install(pkg, prompt = FALSE)
      }
      library(pkg, character.only = T)
    }
  )
)


# Load required functions
source(here("_common", "R", "startLog.r"))
source(here("_common", "R", "logMessage.r"))
source(here("_common", "R", "replaceInto.r"))
source(here("_common", "R", "writeLog.r"))
source(here("_common", "R", "errorMessage.r"))
source(here("_common", "R", "pop.r"))

# Configuration (paths, db_name, etc.)
source(here("config.R"))



# Begin logging
log_file <- startLog(
  file.path(logdir, "listener_logs"),
  "listener_logs"
)


# Set the paths
response <- httr::GET("http://localhost:8080")
content <- jsonlite::fromJSON(
  rawToChar(response$content),
  simplifyDataFrame = FALSE
)
paths <- content[[1]]


# Set the path to the listener log folder
log_path <- paste(logdir, "listener_logs", sep = "/")

# Set the path to unprocessed data folder
data_folder_path <- paths$unprocessed_dir


# Put file information into a dataframe
for (i in seq(length(content) - 1)) {
  if (exists("file_content")) {
    file_content <- rbind(file_content, as.data.frame(pop(content)))
  } else {
    file_content <- as.data.frame(pop(content))
  }
}


tryCatch({
  file_info_df <- file_content
  logMessage("JSON file injested into an R database", log_file)
}, error = function(cnd) {
  logMessage(paste("Error occurred:", conditionMessage(cnd)), log_file)
  errorMessage(cnd, log_file)
})



# Keep only files with type ".csv", ".xlsx", or ".xls"
for (i in nrow(file_info_df):1) {
  tryCatch({
    if (!(file_info_df$Type[i] %in% c(".csv", ".xlsx", ".xls"))) {
      current_filename <- file_info_df$Name[i]
      current_filepath <- paste(data_folder_path, current_filename, sep = "\\")
      
      file_info_df <- file_info_df[-i, , drop = FALSE]
      logMessage(paste("Unsupported file type:", current_filepath), log_file)
    }
  }, error = function(cnd) {
    logMessage(paste("Error occurred in iteration", i, ": ", conditionMessage(cnd)), log_file)
    errorMessage(cnd, log_file)
    print(paste("Error occurred in iteration", i, ": ", conditionMessage(cnd)))
  })
}


# Load or initialize counter for task_scheduler_id
counter_file <- file.path(log_path, "task_scheduler_counter.txt")


# Create the log file if it doesn't exist
if (!file.exists(counter_file)) {
  write("0", file = counter_file)
}


# Schedule the ingestion
if (nrow(file_info_df) > 0) {
  # Logic to apply
  size_threshold <- 100 # Change to the proper size
  
  # Read the current counter value
  task_scheduler_counter <- as.numeric(readLines(counter_file))
  
  # Define the R script to be scheduled
  scheduled_script <- paths$script_path 
  
  scheduled_script <- "C:/OHS-Project-1/watcher_obj/test_listener_r.r" #TODO:: DELETE
  
  # Case 1: Exactly one file and size < 100
  if (nrow(file_info_df) == 1 && file_info_df$Size[1] < size_threshold) {
    
    # Increment counter for task_scheduler_id
    task_scheduler_counter <- task_scheduler_counter + 1
    
    # Generate taskname and task_scheduler_id
    current_taskname <- paste("PIR_Ingestion_", task_scheduler_counter, sep = "")
    
    # Get current file name and create the path for it
    current_filename <- file_info_df$Name[1]
    current_filepath <- paste(data_folder_path, current_filename, sep = "/")
    
    # Schedule the task using using the schtasks utility, which is a Windows command-line tool for managing scheduled tasks.
    command <- paste(
      file.path(Sys.getenv("R_HOME"), "bin", "Rscript.exe"),
      scheduled_script,
      paste(current_filepath, collapse = " "),
      ">>",
      gsub("\\.R$", "\\.log", scheduled_script),
      "2>&1"
    )
    
    command_path <- file.path(
      log_path, paste0("pir_ingestion", task_scheduler_counter, ".bat")
    )
    
    writeLines(
      command,
      command_path
    )
    
    cmd <- paste(
      'schtasks /CREATE /TN', current_taskname,
      '/TR', '"', command_path, '"',
      '/SC ONCE /SD', format(Sys.Date(), "%m/%d/%Y"),
      '/ST', format(Sys.time() + 62, "%H:%M") # THIS TIME SHOULD BE UPDATED
    )
    system(cmd, intern = TRUE)
    
    # Log the scheduled task
    logMessage(paste("Immediate ingestion scheduled for file:", current_filepath, ": Task #", task_scheduler_counter), log_file)
    
    cat("Ingestion scheduled successfully.\n") # Print to console
  }
  
  # Case 2: Exactly one row and size >= 100
  else if (nrow(file_info_df) == 1 && file_info_df$Size[1] >= size_threshold) {
    
    # Increment counter for task_scheduler_id
    task_scheduler_counter <- task_scheduler_counter + 1
    
    # Generate taskname and task_scheduler_id
    current_taskname <- paste("PIR_Ingestion_", task_scheduler_counter, sep = "")
    
    # Get current file name and create the path for it
    current_filename <- file_info_df$Name[1]
    current_filepath <- paste(data_folder_path, current_filename, sep = "/")
    
    # Schedule the task using using the schtasks utility, which is a Windows command-line tool for managing scheduled tasks.
    command <- paste(
      file.path(Sys.getenv("R_HOME"), "bin", "Rscript.exe"),
      scheduled_script,
      paste(current_filepath, collapse = " "),
      ">>",
      gsub("\\.R$", "\\.log", scheduled_script),
      "2>&1"
    )
    
    command_path <- file.path(
      log_path, paste0("pir_ingestion", task_scheduler_counter, ".bat")
    )
    
    writeLines(
      command,
      command_path
    )
    
    cmd <- paste(
      'schtasks /CREATE /TN', current_taskname,
      '/TR', '"', command_path, '"',
      '/SC ONCE /SD', format(Sys.Date() + 1, "%m/%d/%Y"),
      '/ST 03:00' # Set the time to 3 AM
    )
    system(cmd, intern = TRUE)
    
    # Log that ingestion is delayed
    logMessage(paste("File ingestion scheduled at 3am for file:", current_filepath, ": Task #", task_scheduler_counter), log_file)
    
    cat("Ingestion scheduled at 3:00am due to file size.\n") # Print to console
  }
  
  # Case 3: More than one row
  else if (nrow(file_info_df) > 1) {
    
    # Increment counter for task_scheduler_id
    task_scheduler_counter <- task_scheduler_counter + 1
    
    # Generate taskname and task_scheduler_id
    current_taskname <- paste("PIR_Ingestion_", task_scheduler_counter, sep = "")
    
    # Create an empty list to store file paths
    file_paths_list <- list()
    
    # Iterate over files
    for (row in 1:nrow(file_info_df)) {  
      # Get current file name and create the path for it
      current_filename <- file_info_df$Name[row]
      #current_filepath <- paste0(data_folder_path, current_filename)
      current_filepath <- paste(data_folder_path, current_filename, sep = "/")
      # Add the current file path to the list
      file_paths_list[[row]] <- current_filepath
    }
    
    # Schedule the task using using the schtasks utility, which is a Windows command-line tool for managing scheduled tasks.
    command <- paste(
      file.path(Sys.getenv("R_HOME"), "bin", "Rscript.exe"),
      scheduled_script,
      paste(file_paths_list, collapse = " "),
      ">>",
      gsub("\\.R$", "\\.log", scheduled_script),
      "2>&1"
    )
    
    command_path <- file.path(
      log_path, paste0("pir_ingestion", task_scheduler_counter, ".bat")
    )
    
    writeLines(
      command, 
      command_path
    )
    
    cmd <- paste(
      'schtasks /CREATE /TN', current_taskname,
      '/TR', '"', command_path, '"',
      '/SC ONCE /SD', format(Sys.Date() + 1, "%m/%d/%Y"),
      '/ST 03:00' # Set the time to 3 AM
    )
    system(cmd, intern = TRUE)
    
    # Log that files will be batch processed and scheduled later
    logMessage(paste("File ingestion scheduled at 3am for files:", file_paths_list, ": Task #", task_scheduler_counter), log_file)
    
    cat("Batch processing of files. Ingestion scheduled at 3:00am.\n") # Print to console
  }
  
  # Save the updated counter to the file
  writeLines(as.character(task_scheduler_counter), counter_file)
  
} else {
  # Log that no task is scheduled
  logMessage("No new files found", log_file)
  
  
  cat("No new files found. Task not scheduled.\n") # Print to console
}






# Write log and connect to DB
writeLog(log_file)








