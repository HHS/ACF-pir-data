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
  "tidyr", "dplyr", "officer", "assertr", 
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
source(here("config.R"))

# Set up parallelization
future::plan(multisession, workers = 2)

# Get file
args <- commandArgs(TRUE)

# Functions ----

walk(
  list.files(here("utils"), full.names = T),
  source
)
print(args)
stop()

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

# Get workbooks
tryCatch(
  {
    wb_list <- list.files(
      file.path(datadir),
      pattern = "pir_export_.*.xlsx",
      full.names = T
    )
    logMessage("PIR workbooks found.")
  },
  error = function(cnd) {
    logMessage("Failed to find PIR workbooks.")
    errorMessage(cnd)
  }
)


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

# Clean up
gc()
print(doc, target = file.path(logdir, "automated_pipeline_logs", "ingestion.docx"))

# Load to DB ----

# Write data - This method breaks the foreign key associations

insertData <- function(conn, df, table) {
  
  query <- paste(
    "REPLACE INTO",
    table,
    "(",
    paste(names(df), collapse = ","),
    ")",
    "VALUES",
    "(",
    paste0(
      "?",
      vector(mode = "character", length = length(names(df))),
      collapse = ","
    ),
    ")"
  )
  print(query)
  dbExecute(conn, query, params = unname(as.list(df)))
}

wb_appended <- future_map(
  c("response", "question", "program"),
  function(table) {
    if (table == "program") {
      wb_appended[[table]] %>%
        distinct(uid, .keep_all = T) %>%
        return()
    } else if (table == "question") {
      wb_appended[[table]] %>%
        distinct(question_id, .keep_all = T) %>%
        return()
    } else {
      wb_appended[[table]] %>%
        return()
    }
  }
)
names(wb_appended) <- c("response", "question", "program")

walk(
  c("program", "question", "response"),
  function(table) {
    insertData(conn, wb_appended[[table]], table)
  }
)

dbDisconnect(conn)