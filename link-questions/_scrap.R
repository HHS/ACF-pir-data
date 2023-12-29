temp <- getTables(conn, link_conn, 2019, 2021)
temp <- checkLinked(temp)
temp <- checkUnlinked(temp)
temp <- checkNextYear(temp)
temp <- cleanQuestions(temp)  

if (!is.null(temp$linked)) {
  replaceInto(link_conn, temp$linked, "linked")
}
if (!is.null(temp$unlinked)) {
  replaceInto(link_conn, temp$unlinked, "unlinked")
}
updateUnlinked(link_conn)

walk(
  1:2,
  function(index) {
    lower_year <- all_years[index + 1]
    upper_year <- all_years[index]
    
    cat(lower_year, upper_year, "\n")
    
    linked_questions <- getTables(conn, link_conn, lower_year, upper_year)
    linked_questions <- checkLinked(linked_questions)
    linked_questions <- checkUnlinked(linked_questions)
    linked_questions <- checkNextYear(linked_questions)
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

#' Question cleaning needs to be updated and need to come up with a way to
#' handle proposed linkages now that pivots are happening before
#' cleaning phase