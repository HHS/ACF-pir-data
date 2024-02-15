library(purrr)
library(here)

files <- list.files(
  here("ingestion", "tests"), 
  pattern = ".xlsx", 
  full.names = T
)
log <- data.frame("run" = NULL, "timestamp" = NULL, "message" = NULL)
attr(log, "run") <- ""
attr(log, "path") <- ""
attr(log, "db") <- ""

test_that(
  "extractPirSheets() returns a list without nulls",
  expect_false(
    any(
      map_lgl(
        extractPirSheets(files, log_file),
        is.null
      )
    )
  )
)
test_that(
  "extractPirSheets() returns an attribute sheets",
  map(
    extractPirSheets(files, log_file),
    function(f) {
      expect_true(
        "sheets" %in% names(attributes(f))
      )
    }
  )
)