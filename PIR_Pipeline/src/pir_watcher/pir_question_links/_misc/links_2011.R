#############################################
## Written by: Reggie Gilliard
## Date: 01/29/2023
## Description: 
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

# Get tables and schemas
schemas <- getSchemas(
  list(conn, link_conn), 
  list("pir_data", "question_links")
)

# Get data
linked_questions <- getTables(conn, link_conn, 2011)
temp2011 <- filter(linked_questions$unlinked_db, year == 2011) %>%
  cross_join(linked_questions$linked_db) %>%
  filter(year.x != year.y) %>%
  mutate(
    question_number_dist = stringdist(question_number.x, question_number.y),
    question_name_dist = stringdist(question_name.x, question_name.y),
    question_text_dist = stringdist(question_text.x, question_text.y),
    section_dist = stringdist(section.x, section.y)
  ) %>%
  mutate(
    dist_sum = rowSums(.[grepl("_dist", names(.), perl = T)])
  ) %>%
  group_by(question_number.x, question_name.x, question_text.x) %>%
  mutate(
    min_dist_sum = min(dist_sum),
  )

temp2011 %>%
  distinct(question_id.y, .keep_all = T) %>%
  filter(section_dist == 0) %>%
  arrange(question_id.x, dist_sum, question_number.y) %>%
  mutate(index = row_number()) %>%
  filter(index <= 20) %>%
  openxlsx::write.xlsx("C:\\OHS-Project-1\\ACF-pir-data\\link-questions\\_misc\\links_2011.xlsx")

temp2023 <- filter(linked_questions$unlinked_db, year == 2023) %>%
  cross_join(linked_questions$linked_db) %>%
  filter(year.x != year.y) %>%
  determineLink()
  mutate(
    question_number_dist = stringdist(question_number.x, question_number.y),
    question_name_dist = stringdist(question_name.x, question_name.y),
    question_text_dist = stringdist(question_text.x, question_text.y),
    section_dist = stringdist(section.x, section.y)
  ) %>%
  mutate(
    dist_sum = rowSums(.[grepl("_dist", names(.), perl = T)])
  ) %>%
  group_by(question_number.x, question_name.x, question_text.x) %>%
  mutate(
    min_dist_sum = min(dist_sum),
  )
