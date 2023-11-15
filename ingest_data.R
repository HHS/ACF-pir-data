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

# Begin documenting
doc <- read_docx()
doc <- body_add_par(doc, "## Functions", style = "heading 2")

# Set up parallelization
future::plan(multisession, workers = 2)

# Functions ----

walk(
  list.files(here("utils"), full.names = T),
  source
)

# Function to log messages to a file
log_message <- function(message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- paste(timestamp, message, "\n")
  date <- format(Sys.Date(), "%Y%m%d")
  logdir <- file.path(logdir, "automated_pipeline_logs")
  cat(
    log_entry, 
    file = file.path(logdir, paste0("ingestion_log", "_", date, ".txt")), 
    append = TRUE
  )
}

# Function to hash a string vector
hashVector <- function(string) {
  hashed <- future_map_chr(
    string,
    rlang::hash
  )
  return(hashed)
}

appendPirSheets <- function(workbook, sheets) {
  
  to_append <- list()
  func_env <- environment()
  
  # Extract the sheets of interest
  walk(
    sheets,
    function(sheet) {
      if (sheet %in% c("Section A", "Section B", "Section C", "Section D")) { #note: some years don't include Section D
        to_append <- append(to_append, sheet)
        assign("to_append", to_append, envir = func_env)
      }
    }
  )
  
  # Reshape the data
  to_append <- map(
    to_append,
    function(sheet) {
      df <- readxl::read_excel(wb_2022, sheet = sheet, skip = 1)
      
      df <- df %>% 
        mutate(across(everything(), as.character)) %>%
        pivot_longer(
          cols = !c(
            "Region", "State", "Grant Number", "Program Number", 
            "Type", "Grantee", "Program", "City", "ZIP Code", "ZIP 4"
          ),
          names_to = "variable",
          values_to = "answer"
        )
    }
  )
  
  # Append the data
  appended <- bind_rows(to_append)
  return(appended)
}

mergePirReference <- function(response, workbook) {
  
  yr <- stringr::str_extract(workbook, "(\\d+).xlsx", group = 1)
  
  # Load reference sheet
  question <- readxl::read_excel(workbook, sheet = "Reference") %>%
    janitor::clean_names()
  
  # Set of unique questions
  response_vars <- unique(response$variable)
  question_vars <- unique(question$question_number) # cannot count on question number to be distinct
  
  # Check that reference has all questions
  response <- assertr::verify(
    response,
    length(setdiff(response_vars, question_vars)) == 0
  ) %>%
    # Merge to appended data
    left_join(
      question,
      by = c("variable" = "question_number"),
      relationship = "many-to-one"
    )
  return(list("response" = response, "question" = question))
}

cleanPirData <- function(df_list, schema, yr) {
  
  addPirVars <- function(list_of_errors, data) {
    for (v in mi_vars) {
      data[v] <- NA_character_
    }
    return(data)
  }
  
  func_env <- environment()
  
  walk(
    names(schema),
    function(table) {
      assign(
        paste0(tolower(table), "_vars"),
        schema[[table]],
        envir = func_env
      )
    }
  )
  
  df_list$response <- df_list$response %>%
    janitor::clean_names() %>%
    rename(program_type = type) %>%
    mutate(
      year = yr,
      uid_hash = paste0(grant_number, program_number, program_type),
      uid = hashVector(uid_hash),
      question_id_hash = paste0(variable, question_text),
      question_id = hashVector(question_id_hash)
    ) %>%
    select(all_of(response_vars))
  
  df_list$question <- df_list$question %>%
    mutate(
      section = gsub("^(\\w).*", "\\1", question_number, perl = T)
    ) %>%
    rename(
      question_type = type
    ) %>%
    mutate(
      year = yr,
      question_id_hash = paste0(question_number, question_text),
      question_id = hashVector(question_id_hash)
    ) %>%
    pipeExpr(
      assign(
        "mi_vars",
        setdiff(question_vars, names(.)),
        envir = func_env
      )
    ) %>%
    assertr::verify(
      length(mi_vars) == 0,
      error_fun = addPirVars
    ) %>%
    select(all_of(question_vars))
  
  df_list$program <- df_list$program %>%
    janitor::clean_names() %>%
    rename(
      program_zip1 = program_zip_code,
      program_zip2 = program_zip_4,
      program_phone = program_main_phone_number,
      program_email = program_main_email
    ) %>%
    mutate(
      year = yr,
      uid_hash = paste0(grant_number, program_number, program_type),
      uid = hashVector(uid_hash)
    ) %>%
    pipeExpr(
      assign(
        "mi_vars",
        setdiff(program_vars, names(.)),
        envir = func_env
      )
    ) %>%
    assertr::verify(
      length(mi_vars) == 0,
      error_fun = addPirVars
    ) %>%
    select(all_of(program_vars))
  
  return(df_list)
}

# Establish DB connection ----

tryCatch(
  {
    conn <- dbConnect(RMariaDB::MariaDB(), dbname = "pir_data", username = dbusername, password = dbpassword)
    log_message("Connection established successfully.")
  },
  error = function(cnd) {
    error_message <- paste("Error:", conditionMessage(cnd))
    log_message(error_message)
    stop(error_message)
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
    log_message("Schemas read from database.")
  },
  error = function(cnd) {
    error_message <- paste("Error:", conditionMessage(cnd))
    log_message(error_message)
    stop(error_message)
  }
)

# Ingestion ----

# Get workbooks

wb_list <- list.files(
  file.path(datadir),
  pattern = "*.xlsx", #filter for "pir_export_"
  full.names = T
)

# Ingest each workbook

wb_2022 <- wb_list[grepl("2022.xlsx", wb_list)] # For now, just 2022

wb_sheets <- readxl::excel_sheets(wb_2022)

wb_appended <- appendPirSheets(wb_2022, wb_sheets)
wb_appended <- mergePirReference(wb_appended, wb_2022)
program <- readxl::read_excel(wb_2022, sheet = "Program Details")
wb_appended <- append(wb_appended, list("program" = program))

yr <- stringr::str_extract(wb_2022, "(\\d+).xlsx", group = 1)
wb_appended <- cleanPirData(wb_appended, schema, yr)
gc()

print(doc, target = file.path(logdir, "automated_pipeline_logs", "ingestion.docx"))
stop()
# Load to DB ----

# Write data - This method breaks the foreign key associations

insertData <- function(conn, df) {
  
  query <- paste(
    "INSERT INTO question",
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

insertData(conn, wb_appended$question)

walk(
  c("response", "program", "question"),
  function(table) {
    dbWriteTable(conn, table, wb_appended[[table]], overwrite = T)
  }
)

# Foreign key references are removed, add them back in here
# Currently does not work because there are some cases where ID is null
# dbSendQuery(conn, "ALTER TABLE `Response` ADD FOREIGN KEY (`uid`) REFERENCES `Program` (`uid`)")
# dbSendQuery(conn, "ALTER TABLE `Response` ADD FOREIGN KEY (`question_id`) REFERENCES `Question` (`question_id`)")
dbDisconnect(conn)