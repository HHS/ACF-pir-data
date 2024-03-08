################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Script to fetch data for the dashboard home page
################################################################################

# Create a table of unique linked and unlinked questions

# Query to get count of unique observations for linked and unlinked tables
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
  # Convert count to integer
  mutate(Count = as.integer(Count)) %>%
  # Reorder columns
  relocate(Table)

# Assign the table to output so we can call it in UI
output$home_uniq_obs <- renderTable(home_unique_obs)

# Create a table of total linked and unlinked questions
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
  # Convert count to integer
  mutate(Count = as.integer(Count)) %>%
  # Reorder columns
  relocate(Table)

# Assign the table to output so we can call it in UI
output$home_tot_obs <- renderTable(home_tot_obs)

# Query to get most recent results
ingestion_query <- dbGetQuery(
  log_conn, 
  "
  SELECT *, 
  CASE
  WHEN message like '%success%' THEN 'Success'
  else 'Failed'
  END AS Status
  FROM pir_ingestion_logs
  WHERE timestamp = (
  	SELECT max(timestamp)
  	FROM pir_ingestion_logs
  )
  order by timestamp, message
  limit 1
  "
)

# Query to get most recent listener log
listener_query <- dbGetQuery(
  log_conn,
  "
  SELECT *, 
  CASE
  WHEN message like '%scheduled%' THEN 'Success'
  else 'Failed'
  END AS Status
  FROM pir_logs.pir_listener_logs
  WHERE timestamp = (
  	SELECT max(timestamp)
  	FROM pir_logs.pir_listener_logs
    )
      order by timestamp, message desc
  limit 1;
  "
)

# Query to get most recent question linkage log
question_query <- dbGetQuery(
  log_conn, 
  "
  SELECT *, 
  CASE
  WHEN message like '%success%' THEN 'Success'
  else 'Failed'
  END AS Status
  FROM pir_logs.pir_question_linkage_logs
  WHERE timestamp = (
  	SELECT max(timestamp)
  	FROM pir_logs.pir_question_linkage_logs
    )
      order by timestamp, message desc
  limit 1;
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
  colnames = c('Run', 'Date', 'Message', 'Status')
)

# Use DT to create an interactive table
listener_logs <- datatable(
  listener_query,
  options = list(dom = 'Bfrtip', buttons = c('copy', 'excel', 'pdf', 'print')),
  rownames = FALSE,
  class = 'cell-border compact stripe',
  colnames = c('Run', 'Date', 'Message', 'Status')
)

# Use DT to create an interactive table
question_logs <- datatable(
  question_query, 
  options = list(dom = 'Bfrtip', buttons = c('copy', 'excel', 'pdf', 'print')),
  rownames = FALSE,
  class = 'cell-border compact stripe',
  colnames = c('Run', 'Date', 'Timestamp', 'Message')
)

# Assign every object to output so we can use it in the UI scripts
output$ingestion_logs <- renderDT({
  ingestion_logs
})


output$listener_logs <- renderDT({
  listener_logs
})


output$question_logs <- renderDT({
  question_logs
})