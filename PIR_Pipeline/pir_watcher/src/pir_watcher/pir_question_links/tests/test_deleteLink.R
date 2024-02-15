library(here)
source(here("link-questions", "tests", "testSetup.R"))

dbExecute(
  test_conn,
  "call copyTables('question_links_test')"
)

to_unlink <- dbGetQuery(
  test_conn,
  "
  SELECT uqid, question_id
  FROM linked
  WHERE uqid IN (
    SELECT uqid
    FROM inconsistent_question_id_v
  )
  LIMIT 1
  "
)
target_uqid <- to_unlink$uqid
target_qid <- to_unlink$question_id

initial_linked_count <- dbGetQuery(
  test_conn,
  "SELECT COUNT(*) FROM linked"
)
initial_unlinked_count <- dbGetQuery(
  test_conn,
  "SELECT COUNT(*) FROM unlinked"
)
obs_count <- dbGetQuery(
  test_conn,
  paste0(
    "SELECT COUNT(*) 
    FROM linked
    WHERE uqid = '", target_uqid, "' AND question_id = '", target_qid, "'" 
  )
)

deleteLink(
  test_conn,
  target_uqid,
  target_qid
)

post_linked_count <- dbGetQuery(
  test_conn,
  "SELECT COUNT(*) FROM linked"
)
post_unlinked_count <- dbGetQuery(
  test_conn,
  "SELECT COUNT(*) FROM unlinked"
)
test_that(
  expect_equal(
    initial_linked_count - obs_count, post_linked_count
  )
)



dbExecute(
  test_conn,
  "call dropTables('question_links_test')"
)
rm(log_file)