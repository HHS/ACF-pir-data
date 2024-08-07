################################################################################
## Written by: Reggie Gilliard
## Date: 11/10/2023
## Description: Ingest data
################################################################################

# Remove objects from the R environment
rm(list = ls())

# Load packages
pkgs <- c(
  "tidyr", "dplyr", "roxygen2", "assertr", 
  "purrr", "RMariaDB", "here", "janitor",
  "furrr", "readxl", "digest", "jsonlite"
)

invisible(sapply(pkgs, library, character.only = TRUE))

# Configuration (paths, db_name, etc.)
config <- jsonlite::fromJSON(here::here("config.json"))
dbusername <- config$dbusername
dbpassword <- config$dbpassword
logdir <- config$Ingestion_Logs

# Set up parallelization
operating_system <- Sys.info()['sysname']
if (operating_system == "Windows") {
  processors <- as.numeric(shell("echo %NUMBER_OF_PROCESSORS%", intern = T))/2
}
future::plan(future::multisession, workers = processors)
options(future.globals.maxSize = 2000*1024^2)

# Load functions 
walk(
  list.files(here::here("pir_ingestion", "utils"), full.names = T, pattern = "R$"),
  source
)
walk(
  list.files(here::here("_common", "R"), full.names = T, pattern = "R$"),
  source
)

# Begin logging
log_file <- startLog("pir_ingestion_logs")

# Establish DB connection 
connections <- connectDB("pir_data", dbusername, dbpassword, log_file)
conn <- connections$pir_data
tables <- c("response", "question", "program", "unmatched_question")
schema <- getSchemas(conn, tables)

# Get file(s) 
args <- commandArgs(TRUE)
wb_list <- args

# Ingestion

# Extract all sheets from PIR workbooks
map(
  wb_list,
  function(workbook) {
    year <- stringr::str_extract(workbook, "(\\d+).(csv|xlsx?)", group = 1)
    year <- as.numeric(year)
    # If year is 2008 or later, use the standard PIR ingestion, otherwise use the function for older data
    if (year >= 2008) {
      pirIngest(workbook)
    } else {
      pirIngestOld(workbook)
    }
    gc()
  }
)

# Write log and connect to DB
logMessage("Successfully ingested PIR data", log_file)
writeLog(log_file)
dbDisconnect(conn)
gc()

