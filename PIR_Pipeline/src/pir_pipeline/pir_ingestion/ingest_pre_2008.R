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
  # "C:\\Users\\reggie.gilliard\\repos\\ACF-pir-data\\data\\pir_export_2003.xlsx",
  # "C:\\Users\\reggie.gilliard\\repos\\ACF-pir-data\\data\\pir_export_2004.xlsx",
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

response <- attr(workbooks_temp[[1]], "response")
question <- attr(workbooks_temp[[1]], "question")
program <- attr(workbooks_temp[[1]], "program")

response <- response %>%
  select(
    -ends_with(c(".y"))
  ) %>%
  rename_with(
    ~ gsub("\\.x", "", ., perl = TRUE), ends_with(".x")
  ) %>%
  select(-starts_with("q")) %>%
  rename(
    grant_number = GRNUM,
    delegate_number = DELNUM,
    program_number = SYS_HS_PROGRAM_ID,
    region = RegionNumber
  ) %>%
  select(
    grant_number, delegate_number, region, program_number, matches("\\w\\d")
  )

program <- program %>%
  left_join_check(
    response %>%
      select(grant_number, delegate_number, region),
    by = c("grant_number", "delegate_number"),
    relationship = "one-to-one"
  ) %>%
  assertr::verify(merge == 3) %>%
  select(-c(merge))

response <- response %>%
  mutate(across(everything(), as.character)) %>%
  pivot_longer(
    -c("grant_number", "delegate_number", "region", "program_number"),
    names_to = "question_number",
    values_to = "answer"
  ) %>%
  mutate(
    delegate_number = as.numeric(delegate_number),
    program_number = as.numeric(program_number),
    question_number = gsub(
      "(\\w)(\\d{1,2})(\\w)?(\\w)?(\\w)?",
      "\\1.\\2.\\3.\\4-\\5",
      question_number,
      perl = T
    ),
    question_number = gsub("\\W(?=\\W)|\\W$", "", question_number, perl = T),
    question_number = gsub("\\.0(\\d)", ".\\1", question_number, perl = T)
  )

response %>%
  left_join_check(
    program %>%
      select(grant_number, delegate_number, program_number, program_type),
    by = c("grant_number", "delegate_number", "program_number"),
    relationship = "many-to-one"
  ) %>%
  assertr::verify(merge %in% c(1, 3)) %>%
  filter(merge == 3) %>%
  select(-merge) %>%
  rename(type = program_type) %>%
  left_join_check(
    question %>%
      select(question_number, question_name),
    by = c("question_number"),
    relationship = "many-to-one"
  ) %>%
  filter(merge != 3) %>%
  View()
  assertr::verify(merge == 3) %>%
  assertr::assert(not_na, question_name) %>%
  select(-merge)

attr(workbook, "response") <- response
attr(workbook, "program") <- program