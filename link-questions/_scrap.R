temp <- getTables(conn, link_conn, 2019)
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

walk(
  list.files(here("link-questions", "utils"), full.names = T, pattern = "R$"),
  source
)
walk(
  all_years,
  function(year) {
    
    cat(year, "\n")
    
    linked_questions <- getTables(conn, link_conn, year)
    linked_questions <- checkLinked(linked_questions)
    linked_questions <- checkUnlinked(linked_questions)
    linked_questions <- cleanQuestions(linked_questions)  
    
    if (!is.null(linked_questions$linked)) {
      replaceInto(link_conn, linked_questions$linked, "linked")
    }
    if (!is.null(linked_questions$unlinked)) {
      replaceInto(link_conn, linked_questions$unlinked, "unlinked")
    }
    updateUnlinked(link_conn)
  }
)

# Checks on matches
linked <- dbGetQuery(
  link_conn,
  paste(
    "SELECT *",
    "FROM linked"
  )
)

unlinked <- dbGetQuery(
  link_conn,
  paste(
    "SELECT *",
    "FROM unlinked"
  )
)

verify(NULL, length(intersect(linked$question_id, unlinked$question_id)) == 0)

questions <- dbGetQuery(
  conn,
  paste(
    "SELECT *",
    "FROM question"
  )
)

#' Four questions missing because the text and name are identical, 
#' but number is different.
mi_questions <- setdiff(questions$question_id, c(linked$question_id, unlinked$question_id))
filter(questions, question_id %in% mi_questions)

anti_join(questions, linked, by = c("question_id", "year"))

# Should a user check cases where question_id and uqid are not unique?
linked %>% 
  distinct(question_id, uqid) %>%
  assert(is_uniq, question_id)

linked %>%
  group_by(uqid) %>%
  mutate(num = n()) %>%
  verify(num >= 2)

temp <- df_list$unlinked

proposed_link_ids <- map(
  map(
    temp$proposed_link,
    fromJSON
  ),
  names
)
proposed_link_ids <- unlist(proposed_link_ids)
overlap <- intersect(unlinked$question_id, proposed_link_ids)