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

# Database connection
connections <- connectDB(
  list("pir_data", "question_links"), 
  dbusername, 
  dbpassword, 
  log_file
)
conn <- connections[[1]]
link_conn <- connections[[2]]

jscode <- "shinyjs.refresh_page = function() { history.go(0); }"

# Dashboard meta data
dash_meta <- list()