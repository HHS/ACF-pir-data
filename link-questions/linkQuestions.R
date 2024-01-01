#############################################
## Written by: Reggie Gilliard
## Date: 11/10/2023
## Description: Data ingestion
## ToDo: Error handling, credential management, move functions out
#############################################

# Setup ----

rm(list = ls())

# Packages
pkgs <- c(
  "tidyr", "dplyr", "roxygen2", "assertr", 
  "purrr", "RMariaDB", "here", "janitor",
  "furrr", "readxl", "fuzzyjoin", "stringdist"
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
source("C:\\OHS-Project-1\\ACF-pir-data\\config.R")

# Set up parallelization
operating_system <- Sys.info()['sysname']
if (operating_system == "Windows") {
  processors <- as.numeric(shell("echo %NUMBER_OF_PROCESSORS%", intern = T))/2
}
future::plan(multisession, workers = processors)
options(future.globals.maxSize = 2000*1024^2)

# Get file
args <- commandArgs(TRUE)

# Functions ----

# Common functions
walk(
  list.files(here("_common", "R"), full.names = T, pattern = "R$"),
  source
)

# Question Linking functions
walk(
  list.files(here("link-questions", "utils"), full.names = T, pattern = "R$"),
  source
)

# Begin logging
log_file <- startLog()

# Establish DB connection ----

tryCatch(
  {
    conn <- dbConnect(RMariaDB::MariaDB(), dbname = "pir_data_2", username = dbusername, password = dbpassword)
    logMessage("Connection established to PIR database successfully.", log_file)
    link_conn <- dbConnect(
      RMariaDB::MariaDB(), dbname = "question_links", 
      username = dbusername, password = dbpassword
    )
    logMessage("Connection established question linking database successfully.", log_file)
  },
  error = function(cnd) {
    errorMessage(cnd, log_file)
  }
)

# Get tables and schemas
tryCatch(
  {
    tables <- dbGetQuery(link_conn, "SHOW TABLES FROM question_links")[[1]]
    logMessage("List of tables obtained.", log_file)
    schema <- map(
      tables,
      function(table) {
        vars <- dbGetQuery(link_conn, paste("SHOW COLUMNS FROM", table))
        vars <- vars$Field
        return(vars)
      }
    ) %>%
      setNames(tables)
    logMessage("Table schemas obtained.", log_file)
  },
  error = function(cnd) {
    errorMessage(cnd, log_file)
    logMessage("Failed to obtain list of tables/table schemas.", log_file)
  }
)

# Extract years from question table
all_years <- dbGetQuery(
  conn,
  "
    SELECT distinct year
    from question
  "
)$year
all_years <- sort(all_years, decreasing = T)

# Loop over all years and match questions
walk(
  all_years,
  function(year) {
    
    cat(year, "\n")
    
    linked_questions <- getTables(conn, link_conn, year)
    linked_questions <- checkLinked(linked_questions)
    linked_questions <- checkUnlinked(linked_questions)
    linked_questions <- cleanQuestions(linked_questions)  
    
    if (!is.null(linked_questions$linked)) {
      replaceInto(link_conn, linked_questions$linked, "linked")
    }
    if (!is.null(linked_questions$unlinked)) {
      replaceInto(link_conn, linked_questions$unlinked, "unlinked")
    }
    updateUnlinked(link_conn)
  }
)