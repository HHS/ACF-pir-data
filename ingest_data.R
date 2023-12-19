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
  "furrr", "readxl"
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

walk(
  list.files(file.path(codedir, "utils"), full.names = T, pattern = "R$"),
  source
)

# Begin logging
log_file <- startLog(file.path(logdir, "automated_pipeline_logs"))

# Establish DB connection ----

tryCatch(
  {
    conn <- dbConnect(RMariaDB::MariaDB(), dbname = "pir_data_2", username = dbusername, password = dbpassword)
    logMessage("Connection established successfully.", log_file)
  },
  error = function(cnd) {
    errorMessage(cnd)
  }
)
tables <- c("response", "question", "program", "unmatched_response", "unmatched_question")

tryCatch(
  {
    schema <- list()
    walk(
      tables,
      function(table) {
        vars <- dbGetQuery(conn, paste("SHOW COLUMNS FROM", table))
        vars <- vars$Field
        schema[[table]] <- vars
        assign("schema", schema, envir = .GlobalEnv)
      }
    )
    logMessage("Schemas read from database.", log_file)
  },
  error = function(cnd) {
    logMessage("Failed to read schemas from database.", log_file)
    errorMessage(cnd)
  }
)

# Ingestion ----

# wb_list <- args
wb_list <- c(
  # "C:\\OHS-Project-1\\data_repository\\pir_export_2008.xls",
  "C:\\OHS-Project-1\\data_repository\\pir_export_2023.xlsx"
)
# Get workbooks
# tryCatch(
#   {
#     wb_list <- list.files(
#       file.path(datadir),
#       pattern = "pir_export_.*.xlsx$",
#       full.names = T
#     )
#     logMessage("PIR workbooks found.", log_file)
#   },
#   error = function(cnd) {
#     logMessage("Failed to find PIR workbooks.", log_file)
#     errorMessage(cnd)
#   }
# )

# Ingest each workbook

# Get list of sheets in each workbook
# tryCatch(
#   {
#     wb_sheets <- map(
#       wb_list,
#       excel_sheets
#     )
#     logMessage("Sheets successfully extracted.", log_file)
#   },
#   error = function(cnd) {
#     logMessage("Failed to extract worksheets.", log_file)
#     errorMessage(cnd)
#   }
# )

# Append section sheets
tryCatch(
  {
    wb_appended <- future_map(
      wb_list,
      appendPirSections
    )
    logMessage("Successfully appended section sheets.", log_file)
  },
  error = function(cnd) {
    logMessage("Failed to append PIR sections.", log_file)
    errorMessage(cnd)
  }
)
gc()

# Load reference and program sheets
tryCatch(
  {
    wb_appended <- future_map2(
      wb_appended,
      wb_list,
      loadQuestionProgram
    )
    logMessage("Successfully loaded reference and program sheets.", log_file)
  },
  error = function(cnd) {
    logMessage("Failed to load reference and/or program sheet.", log_file)
    errorMessage(cnd)
  }
)
gc()

# Merge reference sheet to section sheets
tryCatch(
  {
    wb_appended <- future_map2(
      wb_appended,
      wb_list,
      mergePirReference
    )
    logMessage("Successfully merged reference sheet(s).", log_file)
  },
  error = function(cnd) {
    logMessage("Failed to merge Reference sheet(s).", log_file)
    errorMessage(cnd)
  }
)
gc()

# Final cleaning
tryCatch(
  {
    wb_appended <- future_map2(
      wb_appended,
      wb_list,
      function(df_list, workbook) {
        yr <- stringr::str_extract(workbook, "(\\d+).xls.?", group = 1)
        df_list <- cleanPirData(df_list, schema, yr)
        return(df_list)
      }
    )
    logMessage("Successfully cleaned PIR data.", log_file)
  },
  error = function(cnd) {
    logMessage("Failed to clean PIR data.", log_file)
    errorMessage(cnd)
  }
)
gc()

# Append like Files
wb_appended <- future_map(
  tables,
  function(table) {
    df <- map(
      wb_appended,
      function(df_list) {
        df_list[[table]]
      }
    ) %>%
      bind_rows()
  }
)
names(wb_appended) <- tables
gc()

# Write to DB ----

# Write data

wb_appended <- future_map(
  tables,
  function(table) {
    if (table == "program") {
      wb_appended[[table]] %>%
        distinct(uid, year, .keep_all = T) %>%
        return()
    } else if (table == "question") {
      wb_appended[[table]] %>%
        distinct(question_id, year, .keep_all = T) %>%
        return()
    } else {
      wb_appended[[table]] %>%
        return()
    }
  }
)
names(wb_appended) <- tables

tryCatch(
  {
    walk(
      tables,
      function(table) {
        replaceInto(conn, wb_appended[[table]], table)
      }
    )
    logMessage("Successfully inserted data into DB.", log_file)
  },
  error = function(cnd) {
    logMessage("Failed to insert data into DB.", log_file)
    errorMessage(cnd)
  }
)

dbDisconnect(conn)
gc()