cleanQuestions <- function(qlist) {
  require(uuid)
  require(assertr)
  require(stringr)
  
  linked <- qlist$linked %>%
    mutate(uqid = uuid::UUIDgenerate(n = nrow(.))) %>%
    assert(is_uniq, uqid) %>%
    select(matches(attr(., "db_vars")), -matches(c("year", "dist", "subsection"))) %>%
    pivot_longer(
      !c(uqid),
      names_to = c(".value", "year"),
      names_pattern = "^(\\w+)(\\d{4})$"
    ) %>%
    mutate(year = as.numeric(year))
  
  years <- attr(qlist$unlinked, "years")
  
  unlinked <- qlist$unlinked %>%
    select(matches(attr(., "db_vars")), -matches(c("year", "dist", "subsection"))) %>%
    {
      bind_cols(
        .,
        list_cbind(
          map(
            years,
            function(x) {
              proposed_var <- paste0("proposed_link", x)
              id_var <- ifelse(
                x == years[1],
                paste0("question_id", years[2]),
                paste0("question_id", years[1])
              )
              mutate(., !!proposed_var := !!sym(paste(id_var))) %>%
                select(all_of(proposed_var))
            }
          )
        )
      )
    } %>%
    pivot_longer(
      everything(),
      names_to = c(".value", "year"),
      names_pattern = "^(\\w+)(\\d{4})$"
    ) %>%
    mutate(year = as.numeric(year)) %>%
    group_by(
      year, question_id, question_name, question_text, question_number, category, section
    ) %>%
    summarize(proposed_link = paste0(proposed_link, collapse = ",")) %>%
    ungroup() %>%
    # mutate(
    #   proposed_link = as.character(proposed_link),
    #   proposed_link = str_replace_all(proposed_link, c("^c\\(" = "[", "\\)$" = "]", "\\\"" = "'"))
    # ) %>%
    assert_rows(
      col_concat,
      is_uniq,
      year, question_id
    )
  
  return(
    list("linked" = linked, "unlinked" = unlinked)
  )
}

