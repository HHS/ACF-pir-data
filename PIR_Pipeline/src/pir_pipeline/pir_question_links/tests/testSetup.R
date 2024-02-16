library(here)
requirePackages(c("testthat", "RMariaDB"))
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


log_file <- startLog("","")
connections <- connectDB("pir_tests", dbusername, dbpassword, log_file)
test_conn <- connections$pir_tests