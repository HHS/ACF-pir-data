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
source(here("config.R"))

# Set up parallelization
operating_system <- Sys.info()['sysname']
if (operating_system == "Windows") {
  processors <- as.numeric(shell("echo %NUMBER_OF_PROCESSORS%", intern = T))/2
}
future::plan(multisession, workers = processors)
options(future.globals.maxSize = 2000*1024^2)

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
log_file <- startLog(
  file.path(logdir, "automated_pipeline_logs", "question_linkage"),
  "pir_question_linkage_logs"
)

# Establish DB Connections
connections <- connectDB(
  list("pir_data_test", "pir_question_links"), 
  dbusername, 
  dbpassword, 
  log_file
)
conn <- connections[[1]]
link_conn <- connections[[2]]

# Get tables and schemas
schemas <- getSchemas(
  list(conn, link_conn), 
  list("pir_data_test", "pir_question_links")
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
    
    tryCatch(
      {
        linked_questions <- getTables(conn, link_conn, year)
        logMessage(
          "Successfully extracted tables needed for linking.",
          log_file
        )
      },
      error = function(cnd) {
        logMessage(
          "Failed to extract tables needed for linking",
          log_file
        )
        errorMessage(cnd, log_file)
      }
    )
    
    tryCatch(
      {
        linked_questions <- checkLinked(linked_questions)
        logMessage(
          paste(year, "matched with linked questions table."),
          log_file
        )
      },
      error = function(cnd) {
        logMessage(
          paste("Failed to match", year, "with linked questions table."),
          log_file
        )
        errorMessage(cnd, log_file)
      }
    )
    
    tryCatch(
      {
        linked_questions <- checkUnlinked(linked_questions)
        logMessage(
          paste(year, "matched with unlinked questions table."),
          log_file
        )
      },
      error = function(cnd) {
        logMessage(
          paste("Failed to match", year, "with unlinked questions table."),
          log_file
        )
        errorMessage(cnd, log_file)
      }
    )
    
    tryCatch(
      {
        linked_questions <- cleanQuestions(linked_questions)
        logMessage(
          "Newly linked questions prepared for insertion.",
          log_file
        )
      },
      error = function(cnd) {
        logMessage(
          paste("Failed to prepare newly linked questions for insertion."),
          log_file
        )
        errorMessage(cnd, log_file)
      }
    )
    
    tryCatch(
      {
        if (!is.null(linked_questions$linked)) {
          replaceInto(link_conn, linked_questions$linked, "linked")
        }
        logMessage(
          "Inserted questions into linked table.",
          log_file
        )
      },
      error = function(cnd) {
        logMessage(
          paste("Failed to insert questions into linked table."),
          log_file
        )
        errorMessage(cnd, log_file)
      }
    )
    
    tryCatch(
      {
        if (!is.null(linked_questions$unlinked)) {
          replaceInto(link_conn, linked_questions$unlinked, "unlinked")
        }
        logMessage(
          "Inserted questions into unlinked table.",
          log_file
        )
      },
      error = function(cnd) {
        logMessage(
          paste("Failed to insert questions into unlinked table."),
          log_file
        )
        errorMessage(cnd, log_file)
      }
    )
    
    tryCatch(
      {
        updateUnlinked(link_conn)
        logMessage(
          "Successfully removed any linked questions from unlinked table.",
          log_file
        )
      },
      error = function(cnd) {
        logMessage(
          "Failed to remove linked questions from unlinked table.",
          log_file
        )
        errorMessage(cnd, log_file)
      }
    )
  }
)

# Ad-hoc links
tryCatch(
  {
    adHocLinks(link_conn)
    logMessage(
      "Ad-hoc linkages made",
      log_file
    )
  },
  error = function(cnd) {
    logMessage(
      "No ad-hoc linkages made",
      log_file
    )
    errorMessage(cnd, log_file)
  }
)

writeLog(log_file)
map(connections, dbDisconnect)
