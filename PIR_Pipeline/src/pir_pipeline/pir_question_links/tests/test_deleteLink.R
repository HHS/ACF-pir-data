library(here)
source(here("pir_question_links", "tests", "testSetup.R"))

dbExecute(
  test_conn,
  "call copyTables('pir_question_links')"
)

question_id_list <- c("806e5ea40f2ea4c1c27d931451c955e9", "00f8984c004df31c96b3732c75363b98")

to_unlink <- dbGetQuery(
  test_conn,
  paste0(
    "
    SELECT uqid, question_id
    FROM linked
    WHERE question_id IN (",
      paste0("'", question_id_list, "'", collapse = ", "),
    ")"
  )
)
target_uqid <- to_unlink$uqid
target_qid <- to_unlink$question_id

results <- purrr::map(
  seq(length(target_qid)),
  function (x) {
    qid <- target_qid[[x]]
    uqid <- target_uqid[[x]]
    print(qid)
    print(uqid)
    deleteLink(
      test_conn,
      uqid,
      qid
    )
    post_linked_count <- dbGetQuery(
      test_conn,
      paste0(
        "SELECT COUNT(*) AS COUNT FROM linked WHERE uqid = '", uqid, "'"
      )
    )$COUNT
    post_unlinked_count <- dbGetQuery(
      test_conn,
      paste0(
        "SELECT COUNT(*) AS COUNT FROM unlinked where question_id = '", qid, "'"
      )
    )$COUNT
    return(list(post_linked_count, post_unlinked_count))
  }
)

print(results)
test_that(
  "Variable no longer exists in linked",
  expect_equal(
    results[2][[1]][[1]], 0
  )
)

test_that(
  "Variable is in unlinked",
  expect_equal(
    results[1][[1]][[2]], 1 
  )
)

dbExecute(
  test_conn,
  "call dropTables('pir_question_links')"
)