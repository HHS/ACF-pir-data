home_unique_obs <- dbGetQuery(
  link_conn,
  "
  SELECT COUNT(DISTINCT question_id) as Count
  FROM linked
  "
) %>%
  mutate(Table = "Linked") %>%
  bind_rows(
    dbGetQuery(
      link_conn,
      "
      SELECT COUNT(DISTINCT question_id) as Count
      FROM unlinked
      "
    ) %>%
      mutate(Table = "Unlinked")
  ) %>%
  mutate(Count = as.integer(Count)) %>%
  relocate(Table)

output$home_uniq_obs <- renderTable(home_unique_obs)

home_tot_obs <- dbGetQuery(
  link_conn,
  "
  SELECT COUNT(*) as Count
  FROM linked
  "
) %>%
  mutate(Table = "Linked") %>%
  bind_rows(
    dbGetQuery(
      link_conn,
      "
      SELECT COUNT(*) as Count
      from unlinked
      "
    ) %>%
      mutate(Table = "Unlinked")
  ) %>%
  mutate(Count = as.integer(Count)) %>%
  relocate(Table)

output$home_tot_obs <- renderTable(home_tot_obs)