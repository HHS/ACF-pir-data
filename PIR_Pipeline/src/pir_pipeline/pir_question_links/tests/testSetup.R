library(here)
# Configurations
config <- jsonlite::fromJSON(here::here("config.json"))
dbusername <- config$dbusername
dbpassword <- config$dbpassword

# Common functions
purrr::walk(
  list.files(here("_common", "R"), full.names = T, pattern = "R$"),
  source
)
purrr::walk(
  list.files(here("pir_question_links", "utils"), full.names = T, pattern = "R$"),
  source
)
requirePackages(c("testthat", "RMariaDB"))

log_file <- startLog("")
connections <- connectDB("pir_tests", dbusername, dbpassword, log_file)
test_conn <- connections$pir_tests