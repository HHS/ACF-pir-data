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

# ONLY GET THE MOST RECENT SET OF RESULTS
ingestion_query <- dbGetQuery(
  log_conn, 
  "
  SELECT *
  FROM pir_ingestion_logs
  WHERE run = (
  	SELECT max(run)
  	FROM pir_ingestion_logs
  )
  "
)

listener_query <- dbGetQuery(
  log_conn,
  "
  SELECT *
  FROM listener_logs
  WHERE run = (
  	SELECT max(run)
  	FROM listener_logs
  )
  "
)

question_query <- dbGetQuery(
  log_conn, 
  "
  SELECT *
  FROM pir_question_linkage_logs
  WHERE run = (
  	SELECT max(run)
  	FROM pir_question_linkage_logs
  )
  "
)

# Check if there is any data after reading files
if (nrow(ingestion_query) == 0) {
  stop("No data found in the log files.")
}


# Use DT to create an interactive table
ingestion_logs <- datatable(
  ingestion_query, 
  options = list(dom = 'Bfrtip', buttons = c('copy', 'excel', 'pdf', 'print')),
  rownames = FALSE,
  class = 'cell-border compact stripe',
  colnames = c('Run', 'Date', 'Message')
)

# Use DT to create an interactive table
listener_logs <- datatable(
  listener_query,
  options = list(dom = 'Bfrtip', buttons = c('copy', 'excel', 'pdf', 'print')),
  rownames = FALSE,
  class = 'cell-border compact stripe',
  colnames = c('Run', 'Date', 'Message')
)


question_logs <- datatable(
  question_query, 
  options = list(dom = 'Bfrtip', buttons = c('copy', 'excel', 'pdf', 'print')),
  rownames = FALSE,
  class = 'cell-border compact stripe',
  colnames = c('Run', 'Timestamp', 'Message')
)

output$ingestion_logs <- renderDT({
  ingestion_logs
})


output$listener_logs <- renderDT({
  listener_logs
})


output$question_logs <- renderDT({
  question_logs
})