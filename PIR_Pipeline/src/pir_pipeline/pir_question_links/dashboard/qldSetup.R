#############################################
## Written by: Reggie Gilliard
## Date: 01/05/2023
## Description: Question Linking Dashboard setup
#############################################

rm(list = ls())

# Packages
pkgs <- c(
  "shiny", "here", "dplyr", "kableExtra", "RMariaDB", 
  "shinyjs", "purrr", "tidyr", "stringr", "DT"
)
invisible(sapply(pkgs, library, character.only = T))

# Configuration (paths, db_name, etc.)
config <- jsonlite::fromJSON(here("config.json"))
dbusername <- config$dbusername
dbpassword <- config$dbpassword
logdir <- config$Ingestion_Logs

# Common functions
walk(
  list.files(here("_common", "R"), full.names = T, pattern = "R$"),
  source
)
walk(
  list.files(here("pir_question_links", "utils"), full.names = T, pattern = "R$"),
  source
)


# Logging
log_file <- startLog("pir_question_linkage_logs")

# Dashboard meta data
dash_meta <- list()

# Database connection
info_conn <- connectDB("information_schema", dbusername, dbpassword, log_file)[[1]]
dash_meta$dbnames <- dbGetQuery(
  info_conn,
  "
  SHOW SCHEMAS
  "
)$Database
dash_meta$dbnames <- grep("pir|question", dash_meta$dbnames, value = TRUE)

connections <- connectDB(
  dash_meta$dbnames, 
  dbusername, 
  dbpassword, 
  log_file
)

conn <- connections$pir_data
link_conn <- connections$question_links_test
log_conn <- connections$pir_logs

jscode <- "shinyjs.refresh_page = function() { history.go(0); }"