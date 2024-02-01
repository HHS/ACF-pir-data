intermittentIDMatch <- function(conn, id) {
  func_env <- environment()
  
  linked <- dbGetQuery(
    conn,
    paste(
      "SELECT *",
      "FROM linked"
    )
  )
  
  unlinked <- dbGetQuery(
    conn,
    "
    SELECT *
    FROM unlinked
    "
  )
  
  sample <- linked %>%
    filter(uqid == id) %>%
    pipeExpr(assign("sample_years", unique(.$year), func_env)) %>%
    mutate(across(c("question_name", "question_text", "question_number"), fedmatch::clean_strings)) %>%
    distinct(question_id, .keep_all = T) %>%
    select(-c(category)) %>%
    rename(question_id_base = question_id)
  
  pool <- linked %>%
    filter(uqid != id & year %notin% sample_years) %>%
    select(starts_with("question"), section, year) %>%
    rbind(
      unlinked %>%
        filter(year %notin% sample_years) %>%
        select(starts_with("question"), section, year)
    ) %>%
    mutate(across(c("question_name", "question_text", "question_number"), fedmatch::clean_strings)) %>%
    distinct(question_id, .keep_all = T) %>%
    rename(question_id_proposed = question_id)
  
  match <- fedmatch::merge_plus(
    sample, pool,
    by = c("question_name", "question_text", "question_number", "section"),
    match_type = "multivar",
    unique_key_1 = "question_id_base",
    unique_key_2 = "question_id_proposed",
    suffixes = c("_base", "_proposed"),
    multivar_settings = fedmatch::build_multivar_settings(
      compare_type = c("wgt_jaccard_dist", "wgt_jaccard_dist", "wgt_jaccard_dist", "indicator"),
      wgts = c(.15, .15, .15, .55)
    )
  )
  
  return(match)
}