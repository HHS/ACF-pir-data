#############################################
## Written by: Reggie Gilliard
## Date: 01/05/2023
## Description: Question Linking Dashboard setup
#############################################

rm(list = ls())

# Packages
pkgs <- c("shiny", "here", "dplyr", "kableExtra", "RMariaDB", "shinyjs", "purrr")
invisible(sapply(pkgs, library, character.only = T))

# Configurations
source(here("config.R"))

# Common functions
walk(
  list.files(here("_common", "R"), full.names = T, pattern = "R$"),
  source
)
walk(
  list.files(here("link-questions", "utils"), full.names = T, pattern = "R$"),
  source
)


# Logging
log_file <- startLog(
  here("logs", "automated_pipeline_logs", "question_linkage"),
  "pir_question_linkage_logs"
)

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
connections <- set_names(
  connections, dash_meta$dbnames
)
conn <- connections$pir_data
link_conn <- connections$question_links

jscode <- "shinyjs.refresh_page = function() { history.go(0); }"