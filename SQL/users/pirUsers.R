#############################################
## Written by: Reggie Gilliard
## Date: 01/05/2023
## Description: Create user SQL scripts
#############################################

rm(list = ls())
pkgs <- c("stringi", "here", "stringr", "purrr")
invisible(sapply(pkgs, require, character.only = T))

passwords <- stri_rand_strings(
  n = 4,
  length = 10,
  pattern = "[A-Za-z0-9]"
)

profiles <- list()

profiles$administrator <- c(
  "DROP USER IF EXISTS 'administrator'@'%';",
  paste0("CREATE USER 'administrator'@'%' IDENTIFIED BY '", passwords[1], "';"),
  "GRANT 'DBA' TO 'administrator'@'%';"
)

profiles$analyst <- c(
  "DROP USER IF EXISTS 'analyst'@'%';",
  paste0("CREATE USER 'analyst'@'%' IDENTIFIED BY '", passwords[2], "';"),
  "GRANT SELECT, INSERT, EXECUTE ON * . * TO 'analyst'@'%';"
)

profiles$developer <- c(
  "DROP USER IF EXISTS 'developer'@'%';",
  paste0("CREATE USER 'developer'@'%' IDENTIFIED BY '", passwords[3], "';"),
  "GRANT 'DBManager', 'DBDEsigner', 'BackupAdmin' TO 'developer'@'%';"
)
# 
# 
# security <- c(
#   "DROP USER IF EXISTS 'security'@'%';",
#   paste0("CREATE USER 'security'@'%' IDENTIFIED BY '", passwords[4], "';"),
# )

walk(
  names(profiles),
  function(profile) {
    text = profiles[[profile]]
    writeLines(
      text,
      here("SQL", "users", paste0("createUser", str_to_title(profile), ".sql"))
    )
  }
)
