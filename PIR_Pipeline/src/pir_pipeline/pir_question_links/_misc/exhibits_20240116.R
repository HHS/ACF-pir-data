#############################################
## Written by: Reggie Gilliard
## Date: 01/16/2024
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
exhibits <- list.files(
  here("link-questions", "_misc"),
  pattern = "exhibit.*sql",
  full.names = T
)

exhibits <- map(
  exhibits,
  function(ex) {
    dbGetQuery(
      link_conn,
      gsub("-- Exhibit \\d|\\\n|\\\t|;", " ", readChar(ex, nchars = 1e3))
    )
  }
)

linked <- dbGetQuery(
  link_conn,
  "SELECT * FROM linked"
)

unlinked <- dbGetQuery(
  link_conn,
  "SELECT * FROM unlinked"
)

# Build workbook ----

wb <- createWorkbook()
map2(
  append(list(linked, unlinked), exhibits),
  c(
    "Linked", "Unlinked", "Linked_uqid_dup", 
    "Linked_qname_diff", "Linked_qtext_diff", "Linked_qnum_diff"
  ),
  function(df, name) {
    addWorksheet(wb, name)
    writeData(wb, name, df)
  }
)
saveWorkbook(
  wb, 
  here("link-questions", "_misc", "question_links_20240116.xlsx"), 
  overwrite = T
)
