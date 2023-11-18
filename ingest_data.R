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

# Append sheets of the PIR data which include responses
appendPirSections <- function(workbook, sheets) {
  
  to_append <- list()
  func_env <- environment()
  
  # Extract the sheets of interest
  walk(
    sheets,
    function(sheet) {
      if (grepl("Section", sheet)) {
        to_append <- append(to_append, sheet)
        assign("to_append", to_append, envir = func_env)
      }
    }
  )

  # Reshape the data
  to_append <- map(
    to_append,
    function(sheet) {
      # Do not load colnames. Extract text and colnames below
      df <- readxl::read_excel(workbook, sheet = sheet, col_names = F)
      names(df) <- df[2, ] %>%
        pivot_longer(
          everything(),
          names_to = "variable",
          values_to = "question_number"
        ) %>%
        group_by(question_number) %>%
        mutate(
          num = row_number()
        ) %>%
        ungroup() %>%
        mutate(
          question_number = ifelse(num != 1, paste(question_number, num, sep = "_"), question_number)
        ) %>%
        {.[["question_number"]]}

      text_df <- df[1,] %>%
        pivot_longer(
          cols = everything(),
          names_to = "variable",
          values_to = "question_name"
        ) %>%
        filter(!is.na(question_name))
      df <- df[3:nrow(df),]
        
      df <- df %>% 
        mutate(across(everything(), as.character)) %>%
        pivot_longer(
          cols = !c(
            "Region", "State", "Grant Number", "Program Number", 
            "Type", "Grantee", "Program", "City", "ZIP Code", "ZIP 4"
          ),
          names_to = "variable",
          values_to = "answer"
        ) %>%
        filter(!is.na("Grant Number"))
      
      attr(df, "text_df") <- text_df
      return(df)
    }
  )
  
  # Append the data
  appended <- bind_rows(to_append)
  text_list <- map(to_append, ~ attr(., "text_df"))
  attr(appended, "text_df") <- bind_rows(text_list)
  return(appended)
}

mergePirReference <- function(response, workbook) {
  
  yr <- stringr::str_extract(workbook, "(\\d+).xlsx", group = 1)
  func_env <- environment()
  
  # Load reference sheet
  question <- readxl::read_excel(workbook, sheet = "Reference") %>%
    janitor::clean_names() %>%
    assert_rows(col_concat, is_uniq, question_number, question_name)
  
  # Set of unique questions
  question_vars <- unique(question$question_number)
  
  # Check that reference has all questions
  response <- response %>%
    # Remove numeric strings added to uniquely identify
    mutate(
      variable = gsub("_\\d+$", "", variable, perl = T)
    ) %>%
    pipeExpr(
      assign("response_vars", unique(.$variable), envir = func_env)
    ) %>%
    assertr::verify(
      length(setdiff(response_vars, question_vars)) == 0
    ) %>%
    # Merge to question_name
    left_join(
      attr(response, "text_df"),
      by = c("variable"),
      relationship = "many-to-one"
    ) %>%
    assertr::verify(!is.na(question_name)) %>%
    # Merge to appended data
    left_join(
      question,
      by = c("variable" = "question_number", "question_name"),
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
      question_id_hash = paste0(variable, question_name),
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
      question_id_hash = paste0(question_number, question_name),
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
    "INSERT INTO",
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