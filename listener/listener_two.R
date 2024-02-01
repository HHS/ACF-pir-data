###################################################
##  Created by: Polina Polskaia
##  Description: Takes information from watcher and schedules the ingestion
##
###################################################

# Setup ----

# Remove all objects from the workspace
rm(list = ls())


# TODO:: Change
# Set directory 
# setwd("C:\\OHS-Project-1\\ACF-pir-data\\") 
# .libPaths("C:/Users/Administrator/AppData/Local/R/win-library/4.3")


# Load required libraries
pkgs <- c(
  "taskscheduleR", "here", "dplyr"
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
source(here("_common", "R", "pop.r"))


# Set the paths
response <- httr::GET("http://localhost:8080")
content <- jsonlite::fromJSON(
  rawToChar(response$content),
  simplifyDataFrame = FALSE
)
paths <- content[[1]]


# Set the path to the listener log folder
log_path <- paths$log_dir

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

# TODO:: Change to put logs into a database
tryCatch({
  # Attempt to read the file into file_info_df
  file_info_df <- file_content
}, error = function(cnd) {
  # Print error message if an error occurs
  print(paste("Error occurred:", conditionMessage(cnd)))
})


# Create logs ----


# Function to log actions
log_action <- function(action, log_path, file_path, task_scheduler_id = NA) {
  # Define a mapping of actions to log messages
  action_logs <- list(
    "unsupported file type" = "Unsupported file type",
    "immediate_ingestion_scheduled" = "Immediate ingestion scheduled for file",
    "ingestion_delayed" = "File ingestion scheduled at 3am",
    "no_scheduled_task" = "No new files found"
    # Add more actions as needed
  )
  
  # Check if the specified action has a corresponding log message
  if (action %in% names(action_logs)) {
    
    # Combine log_path with the fixed file name
    log_file <- file.path(log_path, "activity_log.txt")
    
    # Create the log file if it doesn't exist
    if (!file.exists(log_file)) {
      write("", file = log_file)
    }
    
    log_message <- paste(
      Sys.time(), "-",
      action_logs[[action]], ":", file_path,
      "Task Scheduler ID:", task_scheduler_id,
      sep = " "
    )
    
    # Append log entry to the log file
    write(log_message, file = log_file, append = TRUE)
  } else {
    warning("Unsupported action:", action)
  }
}


# Keep only files with type ".csv", ".xlsx", or ".xls"
for (i in nrow(file_info_df):1) {
  if (!(file_info_df$Type[i] %in% c(".csv", ".xlsx", ".xls"))) {
    current_filename <- file_info_df$Name[i]
    current_filepath <- paste(data_folder_path, current_filename, sep = "\\")
    
    file_info_df <- file_info_df[-i, , drop = FALSE]
    log_action("unsupported file type", log_path, current_filepath)
  }
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
    current_filepath <- paste0(data_folder_path, current_filename)
    
    # Schedule the task using taskscheduleR
    taskscheduler_create(
      taskname = current_taskname,
      rscript = scheduled_script,
      schedule = "ONCE",
      starttime = format(Sys.time() + 62, "%H:%M"),
      rscript_args = list(current_filepath)
    )
    
    # Log the scheduled task
    log_action("immediate_ingestion_scheduled", log_path, current_filepath, task_scheduler_counter)
    
    cat("Task scheduled successfully.\n") # Print to console
  }
  
  # Case 2: Exactly one row and size >= 100
  else if (nrow(file_info_df) == 1 && file_info_df$Size[1] >= size_threshold) {
    
    # Increment counter for task_scheduler_id
    task_scheduler_counter <- task_scheduler_counter + 1
    
    # Generate taskname and task_scheduler_id
    current_taskname <- paste("PIR_Ingestion_", task_scheduler_counter, sep = "")
    
    # Get current file name and create the path for it
    current_filename <- file_info_df$Name[1]
    current_filepath <- paste0(data_folder_path, current_filename)
    
    # # Schedule the task using taskscheduleR
    taskscheduler_create(
      taskname = current_taskname,
      rscript = scheduled_script,
      schedule = "ONCE",
      starttime = "03:00",
      startdate = format(Sys.Date()+1, "%d/%m/%Y"),
      rscript_args = list(current_filepath)
    )
    
    # Log that ingestion should be delayed
    log_action("ingestion_delayed", log_path, current_filepath, task_scheduler_counter)
    
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
      current_filepath <- paste0(data_folder_path, current_filename)
      # Add the current file path to the list
      file_paths_list[[row]] <- current_filepath
    }
    
    # Schedule the task using taskscheduleR
    taskscheduler_create(
      taskname = current_taskname,
      rscript = scheduled_script,
      starttime = "03:00",
      startdate = format(Sys.Date()+1, "%d/%m/%Y"),
      rscript_args = file_paths_list
    )
    
    # Log that files will be batch processed and scheduled later
    log_action("ingestion_delayed", log_path, file_paths_list, task_scheduler_counter)
    
    cat("Batch processing of files. Ingestion scheduled at 3:00am.\n") # Print to console
  }
  
  # Save the updated counter to the file
  writeLines(as.character(task_scheduler_counter), counter_file)
  
} else {
  # Log that no task is scheduled
  log_action("no_scheduled_task", log_path, NA, NA)
  
  cat("No new files found. Task not scheduled.\n") # Print to console
}















