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
workbook <- "C:\\Users\\reggie.gilliard\\repos\\ACF-pir-data\\data\\pir_export_2007.xlsx"
workbook <- extractPirSheets(workbook, log_file)
response_list <- list()
for (sheet in pir_2007_sheets) {
  print(sheet)
  sheet_lower <- tolower(sheet)
  df <- readxl::read_xlsx(workbook, sheet = sheet)
  if (!grepl("program|datadictionary", sheet_lower)) {
    try(
      response_list <- df %>%
        assertr::assert_rows(col_concat, assertr::is_uniq, GRNUM, DELNUM) %>%
        # janitor::clean_names() %>%
        {append(response_list, list(.))}
    )
  }
  else if (grepl("program", sheet_lower)) {
    program <- df %>%
      assertr::assert_rows(assertr::col_concat, assertr::is_uniq, GRNUM, DELNUM)
      # janitor::clean_names()
  }
  else if (grepl("datadictionary", sheet_lower)) {
    question <- df %>%
      janitor::clean_names()
  }
}

response <- purrr::reduce(response_list, 
  function (x, y) {
    df = dplyr::full_join(x, y, by = c("GRNUM", "DELNUM"), relationship = "one-to-one")
    return(df)
  }
)
rm(response_list)

response <- response %>%
  select(-ends_with(c(".y")), -c("InErrorFile", "OldGrant-DelgateNumber", "NewGrant-DelgateNumber", "MailingType")) %>%
  rename_with(
    ~ gsub("\\.x", "", ., perl = TRUE), ends_with(".x")
  ) %>%
  select(-starts_with("q"))

response <- response %>%
  mutate(across(everything(), as.character)) %>%
  pivot_longer(
    -c("GRNUM", "DELNUM"),
    names_to = "question_number",
    values_to = "answer"
  ) %>%
  rename(
    grant_number = GRNUM,
    delegate_number = DELNUM
  ) %>%
  mutate(
    delegate_number = as.numeric(delegate_number)
  )

deduplicate_question <- function(list_of_errors, data) {
  orig_vars <- names(data)
  data %>%
    arrange(pirweb_field_name) %>%
    mutate(
      row = row_number(),
      has_field_name = !is.na(pirweb_field_name),
      sum_has_field_name = sum(has_field_name),
      to_keep = case_when(
        has_field_name == TRUE & sum_has_field_name == 1 ~ TRUE,
        row == 1 ~ TRUE,
        TRUE ~ FALSE
      )
    ) %>%
    filter(to_keep == TRUE) %>%
    mutate(n = n()) %>%
    assertr::verify(n == 1) %>%
    select(orig_vars) %>%
    ungroup() %>%
    return()
}
  
question <- question %>%
  group_by(field_name) %>%
  distinct(field_name, pirweb_field_name, description, .keep_all = TRUE) %>%
  mutate(n = n()) %>%
  assertr::verify(n == 1, error_fun = deduplicate_question)
  
question <- question %>%
  rename(
    question_number = field_name,
    question_text = description,
    type = hses_field_type
    # question_type = hses_field_type
  ) %>%
  mutate(
    question_name = coalesce(hses_field_name, pirweb_field_name, question_text),
    # section = case_when(
    #   grepl("^[ABC]\\d", question_name) ~ gsub("^(\\w).*", "\\1", question_name, perl = TRUE),
    #   TRUE ~ NA_character_
    # ),
    section_response = NA_character_
  )

program_col_names <- lapply(names(program),
  function(x){
    index <- question$question_number == x
    var_name <- question$pirweb_field_name[index]
    if (is.na(var_name)) {
      var_name <- question$hses_field_name[index]
    }
    if (is.null(var_name) || is.na(var_name)) {
      var_name <- question$question_number[index]
    }
    return(var_name)
  }
)

program <- program %>%
  setNames(program_col_names) %>%
  janitor::clean_names() %>%
  rename_with(
    ~ gsub("pgm", "program", .)
  ) %>%
  tidyr::separate(
    program_zip,
    c("program_zip_code", "program_zip_4"),
    5
  ) %>%
  rename(
    program_address_line_1 = program_address1,
    program_address_line_2 = program_address2,
    program_main_email = agency_email,
    program_number = sys_hs_program_id,
    grant_number = grantno,
    delegate_number = delegateno,
    program_main_phone_number = program_phone
  ) %>%
  mutate(region = NA_integer_) %>%
  assertr::assert_rows(col_concat, is_uniq, grant_number, delegate_number)

response <- response %>%
  inner_join_check(
    program %>%
      select(grant_number, delegate_number, program_number, program_type),
    by = c("grant_number", "delegate_number"),
    relationship = "many-to-one"
  ) %>%
  assertr::verify(merge == 3) %>%
  select(-merge) %>%
  rename(type = program_type) %>%
  left_join_check(
    question %>%
      select(question_number, question_name),
    by = c("question_number"),
    relationship = "many-to-one"
  ) %>%
  assertr::verify(merge == 3) %>%
  assertr::assert(not_na, question_name) %>%
  select(-merge)

# Clean Data
for (table in c("question", "response", "program")) {
  attr(workbook, table) <- get(table)
}

workbooks <- cleanPirData(list(workbook), schema, log_file)
