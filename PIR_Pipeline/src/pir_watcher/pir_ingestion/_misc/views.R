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
  "dplyr",  "purrr", "RMariaDB", "here", "openxlsx"
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
operating_system <- Sys.info()['sysname']
if (operating_system == "Windows") {
  processors <- as.numeric(shell("echo %NUMBER_OF_PROCESSORS%", intern = T))/2
}
future::plan(multisession, workers = processors)
options(future.globals.maxSize = 2000*1024^2)

# Functions ----

# Common functions
walk(
  list.files(here("_common", "R"), full.names = T, pattern = "R$"),
  source
)

# Question Linking functions
walk(
  list.files(here("link-questions", "utils"), full.names = T, pattern = "R$"),
  source
)

# Begin logging
log_file <- startLog(
  file.path(logdir, "automated_pipeline_logs", "question_linkage"),
  "pir_question_linkage_logs"
)

# Establish DB Connections
connections <- connectDB(
  list("pir_data", "question_links"), 
  dbusername, 
  dbpassword, 
  log_file
)
conn <- connections[[1]]
link_conn <- connections[[2]]

# Get Data ----
views <- map(
  c("national", "state", "region", "grant", "type"),
  function(lvl) {
    dbGetQuery(
      conn,
      paste0("SELECT * FROM tot_cumul_enr_child_", lvl)
    )
  }
)

# Build workbook ----

wb <- createWorkbook()
map2(
  views,
  c(
    "National", "State", "Region",  "Grant", "Program Type"
  ),
  function(df, name) {
    addWorksheet(wb, name)
    writeData(wb, name, df)
  }
)
saveWorkbook(
  wb, 
  here("ingestion", "_misc", paste0(
    "ingestion_views", 
    format(Sys.Date(), "%Y%m%d"),
    ".xlsx"
  )), 
  overwrite = T
)
