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
  list.files(file.path(codedir, "utils"), full.names = T, pattern = "R$"),
  source
)

# Question Linking functions
walk(
  list.files(
    file.path(codedir, "link-questions", "utils"), 
    pattern = "\\.R$", full.names = T
  ),
  source
)

# Begin logging
log_file <- startLog(file.path(logdir, "automated_pipeline_logs"))

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
    errorMessage(cnd)
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
    errorMessage(cnd)
    logMessage("Failed to obtain list of tables/table schemas.", log_file)
  }
)

linked <- dbGetQuery(
  link_conn,
  "
    SELECT *
    FROM linked
  "
)

q2023 <- dbGetQuery(
  conn,
  "
    SELECT * 
    FROM question
    WHERE YEAR = 2023
  "
) %>%
  mutate(
    across(
      starts_with("question"),
      ~ ifelse(is.na(.), "", .)
    )
  )

q2022 <- dbGetQuery(
  conn,
  "
    SELECT * 
    FROM question
    WHERE YEAR = 2022
  "
) %>%
  mutate(
    across(
      starts_with("question"),
      ~ ifelse(is.na(.), "", .)
    )
  )

q2021 <- dbGetQuery(
  conn,
  "
    SELECT * 
    FROM question
    WHERE YEAR = 2021
  "
) %>%
  mutate(
    across(
      starts_with("question"),
      ~ ifelse(is.na(.), "", .)
    )
  )

linked_questions <- linkQuestions(q2022, q2023)
temp <- cleanQuestions(linked_questions)

replaceInto(link_conn, linked_questions$linked, "linked")
replaceInto(link_conn, temp$unlinked, "unlinked")

lq2 <- linkQuestions(q2021, q2022)
