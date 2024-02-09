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

ingestion_query <- dbGetQuery(log_conn, "select * from pir_ingestion_logs")

ingestion_count <- dbGetQuery(log_conn, "select count(*) from pir_ingestion_logs")

question_query <- dbGetQuery(log_conn, "select * from pir_question_linkage_logs")


# Check if there is any data after reading files
if (nrow(ingestion_query) == 0) {
  stop("No data found in the log files.")
}


# Use DT to create an interactive table
dtTable <- datatable(ingestion_query, 
                     options = list(dom = 'Bfrtip', buttons = c('copy', 'excel', 'pdf', 'print')),
                     rownames = FALSE,
                     class = 'cell-border compact stripe',
                     colnames = c('Run', 'Date', 'Message'))

dtTable2 <- datatable(question_query, 
                      options = list(dom = 'Bfrtip', buttons = c('copy', 'excel', 'pdf', 'print')),
                      rownames = FALSE,
                      class = 'cell-border compact stripe',
                      colnames = c('Run', 'Timestamp', 'Message'))

output$ingestion_logs <- renderDT({
  dtTable
})

output$question_logs <- renderDT({
  dtTable2
})

output$ingestion_count <- renderPrint(ingestion_count[[1]])