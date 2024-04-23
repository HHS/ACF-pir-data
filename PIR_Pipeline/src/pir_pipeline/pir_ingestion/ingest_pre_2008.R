################################################################################
## Written by: Reggie Gilliard
## Date: 04/16/2024
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

# Load Functions
walk(
  list.files(here::here("_common", "R"), full.names = T, pattern = "R$"),
  source
)
walk(
  list.files(here::here("pir_ingestion", "utils"), full.names = T, pattern = "R$"),
  source
)

# Configuration (paths, db_name, etc.)
config <- jsonlite::fromJSON(here::here("config.json"))
dbusername <- config$dbusername
dbpassword <- config$dbpassword
logdir <- config$Ingestion_Logs

# Begin logging
log_file <- startLog("pir_ingestion_logs")

# Establish DB connection 
connections <- connectDB("pir_data", dbusername, dbpassword, log_file)
conn <- connections$pir_data
tables <- c("response", "question", "program", "unmatched_question")
schema <- getSchemas(conn, tables)


# Cleaning
workbook <- c(
  "C:\\Users\\reggie.gilliard\\repos\\ACF-pir-data\\data\\pir_export_2003.xlsx",
  "C:\\Users\\reggie.gilliard\\repos\\ACF-pir-data\\data\\pir_export_2004.xlsx",
  "C:\\Users\\reggie.gilliard\\repos\\ACF-pir-data\\data\\pir_export_2005.xlsx",
  "C:\\Users\\reggie.gilliard\\repos\\ACF-pir-data\\data\\pir_export_2006.xlsx",
  "C:\\Users\\reggie.gilliard\\repos\\ACF-pir-data\\data\\pir_export_2007.xlsx"
)
workbook <- extractPirSheets(workbook, log_file)
workbooks_temp <- loadData(workbook, log_file)
workbooks_temp <- cleanQuestion(workbooks_temp, log_file)
workbooks_temp <- cleanProgram(workbooks_temp, log_file)
workbooks_temp <- cleanResponse(workbooks_temp, log_file)
workbooks_temp <- cleanPirData(workbooks_temp, schema, log_file)
