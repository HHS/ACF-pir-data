#############################################
## Written by: Reggie Gilliard
## Date: 11/10/2023
## Description: Data ingestion
## ToDo: Error handling, credential management, move functions out
#############################################

# Setup ----

rm(list = ls())

# Change directories
response <- httr::GET("http://localhost:8080")
content <- jsonlite::fromJSON(
  rawToChar(response$content),
  simplifyDataFrame = FALSE
)

unprocessed_dir <- content[[1]]$unprocessed_dir
processed_dir <- content[[1]]$processed_dir

setwd("C:\\OHS-Project-1\\ACF-pir-data\\")

# Packages
pkgs <- c(
  "tidyr", "dplyr", "roxygen2", "assertr", 
  "purrr", "RMariaDB", "here", "janitor",
  "furrr", "readxl", "digest"
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

# Configuration (paths, db_name, etc.) 
source(here("config.R"))

# Set up parallelization ----
operating_system <- Sys.info()['sysname']
if (operating_system == "Windows") {
  processors <- as.numeric(shell("echo %NUMBER_OF_PROCESSORS%", intern = TRUE))/2
}
future::plan(multisession, workers = processors)
options(future.globals.maxSize = 2000 * 1024^2)

# Functions ----

walk(
  list.files(here("ingestion", "utils"), full.names = T, pattern = "R$"),
  source
)
walk(
  list.files(here("_common", "R"), full.names = T, pattern = "R$"),
  source
)

# Begin logging ----
log_file <- startLog(
  file.path(logdir, "automated_pipeline_logs", "pir_ingestion_logs"),
  "pir_ingestion_logs"
)

# Establish DB connection ----
conn <- connectDB("pir_data_test", dbusername, dbpassword, log_file)[[1]]
tables <- c("response", "question", "program", "unmatched_response", "unmatched_question")
schema <- getSchemas(conn, tables)
# Get Files ----
# args <- commandArgs(TRUE)
# wb_list <- args
wb_list <- list.files(unprocessed_dir, pattern = "diff", full.names = TRUE)

# Ingestion ----

# Extract all sheets from PIR workbooks
tryCatch(
  {
    wb_appended <- extractPirSheets(wb_list, log_file)
  },
  error = function(cnd) {
    logMessage("Failed to extract PIR data sheets.", log_file)
    errorMessage(cnd, log_file)
  }
)

# Load all data
tryCatch(
  {
    wb_appended <- loadPirData(wb_appended, log_file)
  },
  error = function(cnd) {
    logMessage("Failed to load PIR data.", log_file)
    errorMessage(cnd, log_file)
  }
)

# Append sections into response data
tryCatch(
  {
    wb_appended <- appendPirSections(wb_appended, log_file)
  },
  error = function(cnd) {
    logMessage("Failed to append Section sheet(s).", log_file)
    errorMessage(cnd, log_file)
  }
)

# Merge reference sheet to section sheets
tryCatch(
  {
    wb_appended <- mergePirReferenceDiff(wb_appended, log_file, conn)
  },
  error = function(cnd) {
    logMessage("Failed to merge Reference sheet(s).", log_file)
    errorMessage(cnd, log_file)
  }
)

# Final cleaning
tryCatch(
  {
    wb_appended <- cleanPirData(wb_appended, schema, log_file)
  },
  error = function(cnd) {
    logMessage("Failed to clean PIR data.", log_file)
    errorMessage(cnd, log_file)
  }
)

# Write to DB ----

# Write data
tryCatch(
  {
    insertPirData(conn, wb_appended, schema, log_file)
    logMessage("Successfully inserted data into DB.", log_file)
  },
  error = function(cnd) {
    logMessage("Failed to insert data into DB.", log_file)
    errorMessage(cnd, log_file)
  }
)

# Move Files
tryCatch(
  {
    moveFiles(wb_appended, processed_dir)
    logMessage("Moved files to processed directory.", log_file)
  },
  error = function(cnd) {
    logMessage("Failed to insert data into DB.", log_file)
    errorMessage(cnd, log_file)
  }
)

# Write log and connect to DB
writeLog(log_file)
dbDisconnect(conn)
gc()