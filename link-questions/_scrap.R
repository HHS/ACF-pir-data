temp <- getTables(conn, link_conn, 2022)
temp <- checkLinked(temp)
temp <- checkUnlinked(temp)
temp <- cleanQuestions(temp)  

if (!is.null(temp$linked)) {
  replaceInto(link_conn, temp$linked, "linked")
}
if (!is.null(temp$unlinked)) {
  replaceInto(link_conn, temp$unlinked, "unlinked")
}
updateUnlinked(link_conn)

temp2 <- fedmatch::merge_plus(
  temp$unlinked,
  temp$unlinked_db %>%
    rename(question_id2 = question_id),
  by = c("question_name", "question_text", "question_number", "section"),
  match_type = "multivar",
  multivar_settings = fedmatch::build_multivar_settings(
    compare_type = c("stringdist", "stringdist", "stringdist", "indicator")
  ),
  unique_key_1 = "question_id",
  unique_key_2 = "question_id2",
  suffixes = c("_1", "_2"),
  wgts = c()
)
