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
future::plan(multisession, workers = 2)
options(future.globals.maxSize = 2000*1024^2)

# Get file
args <- commandArgs(TRUE)

# Functions ----

walk(
  list.files(file.path(codedir, "utils"), full.names = T),
  source
)

# Establish DB connection ----

tryCatch(
  {
    conn <- dbConnect(RMariaDB::MariaDB(), dbname = "pir_data_2", username = dbusername, password = dbpassword)
    logMessage("Connection established successfully.")
  },
  error = function(cnd) {
    errorMessage(cnd)
  }
)

tryCatch(
  {
    schema <- list()
    walk(
      c("program", "response", "question"),
      function(table) {
        vars <- dbGetQuery(conn, paste("SHOW COLUMNS FROM", table))
        vars <- vars$Field
        schema[[table]] <- vars
        assign("schema", schema, envir = .GlobalEnv)
      }
    )
    logMessage("Schemas read from database.")
  },
  error = function(cnd) {
    logMessage("Failed to read schemas from database.")
    errorMessage(cnd)
  }
)

# Ingestion ----

# wb_list <- args
wb_list <- "C:\\OHS-Project-1\\data_repository\\pir_export_2015.xlsx"
# Get workbooks
# tryCatch(
#   {
#     wb_list <- list.files(
#       file.path(datadir),
#       pattern = "pir_export_.*.xls$",
#       full.names = T
#     )
#     logMessage("PIR workbooks found.")
#   },
#   error = function(cnd) {
#     logMessage("Failed to find PIR workbooks.")
#     errorMessage(cnd)
#   }
# )
  
# Ingest each workbook

# Get list of sheets in each workbook
tryCatch(
  {
    wb_sheets <- map(
      wb_list,
      excel_sheets
    )
    logMessage("Sheets successfully extracted.")
  },
  error = function(cnd) {
    logMessage("Failed to extract worksheets.")
    errorMessage(cnd)
  }
)

# Append section sheets
tryCatch(
  {
    wb_appended <- future_map2(
      wb_list,
      wb_sheets,
      appendPirSections
    )
    logMessage("Successfully appended section sheets.")
  },
  error = function(cnd) {
    logMessage("Failed to append PIR sections.")
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
    logMessage("Successfully merged reference sheet(s).")
  },
  error = function(cnd) {
    logMessage("Failed to merge Reference sheet(s).")
    errorMessage(cnd)
  }
)
gc()

# Add program sheet to wb_appended lists
tryCatch(
  {
    wb_appended <- future_map2(
      wb_list,
      wb_appended,
      function(workbook, df_list) {
        program <- readxl::read_excel(workbook, sheet = "Program Details")
        df_list <- append(df_list, list("program" = program))
        return(df_list)
      }
    )
    logMessage("Successfully ingested program details.")
  },
  error = function(cnd) {
    logMessage("Failed to ingest program details.")
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
        yr <- stringr::str_extract(workbook, "(\\d+).xlsx", group = 1)
        df_list <- cleanPirData(df_list, schema, yr)
        return(df_list)
      }
    )
    logMessage("Successfully cleaned PIR data.")
  },
  error = function(cnd) {
    logMessage("Failed to clean PIR data.")
    errorMessage(cnd)
  }
)
gc()

# Append like Files
wb_appended <- future_map(
  c("response", "question", "program"),
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
names(wb_appended) <- c("response", "question", "program")
gc()

# Write to DB ----

# Write data
wb_appended <- future_map(
  c("response", "question", "program"),
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
names(wb_appended) <- c("response", "question", "program")

tryCatch(
  {
    walk(
      c("program", "question", "response"),
      function(table) {
        replaceInto(conn, wb_appended[[table]], table)
      }
    )
    logMessage("Successfully inserted data into DB.")
  },
  error = function(cnd) {
    logMessage("Failed to insert data into DB.")
    errorMessage(cnd)
  }
)

dbDisconnect(conn)
