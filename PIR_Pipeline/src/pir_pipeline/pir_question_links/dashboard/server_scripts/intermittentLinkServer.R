################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Script to fetch data for the Intermittent links tab of the dashboard
################################################################################

# Fetch data for the Intermittent links tab of the dashboard
output$intermittent_link <- function() {
  # Get intermittent matches
  if (length(dash_meta$intermittent_uqid_choices) > 0){
    intermittent <- jaccardIDMatch(link_conn, input$intermittent_uqid, "intermittent")$matches 
  } else {
    intermittent <- data.frame()
  }
  # Get unique question IDs and corresponding unique IDs from linked table
  uqids <- dbGetQuery(
    link_conn,
    paste(
      "SELECT DISTINCT question_id, uqid",
      "FROM linked",
      "WHERE question_id IN (", 
        paste0("'", c(intermittent$question_id_base, intermittent$question_id_proposed), "'", collapse = ","),
      ")"
    )
  )
  # Get year range for each unique ID
  year_range <- dbGetQuery(
    link_conn,
    paste(
      "SELECT DISTINCT question_id, uqid, year as year_range",
      "FROM linked",
      "WHERE uqid IN (", 
        paste0("'", uqids$uqid, "'", collapse = ","),
      ")",
      "ORDER BY uqid, year"
    )
  ) %>%
    group_by(uqid) %>%
    summarize(year_range = paste0(year_range, collapse = ", ")) %>%
    ungroup()
  # Prepare intermittent matches data
  intermittent <- intermittent %>%
    mutate(
      id = row_number(),
      across(everything(), as.character)
  ) %>%
  select(id, ends_with(c("proposed", "base"))) %>%
  pivot_longer(
    ends_with(c("base", "proposed")),
    names_to = c(".value", "name"),
    names_pattern = "(\\w+)_(\\w+)$"
  ) %>%
  left_join(
    uqids,
    by = "question_id"
  ) %>%
  left_join(
    year_range,
    by = "uqid"
  ) %>%
  pivot_longer(
    -c(id, name),
    names_to = "column"
  ) %>%
  pivot_wider(
    names_from = c("id", "name"),
    values_from = value,
    names_glue = "{name}_{id}"
  )
  
  # Render table with kableExtra package
  intermittent %>%
    filter(column != 'year') %>% 
    kableExtra::kable() %>%
    kableExtra::kable_styling("striped")
}

# Update select input for proposed links
observeEvent(
  input$intermittent_uqid,
  {
    # Get intermittent matches
    if (length(dash_meta$intermittent_uqid_choices) > 0){
      intermittent <- jaccardIDMatch(link_conn, input$intermittent_uqid, "intermittent")$matches 
    } else {
      intermittent <- data.frame()
    }
    # Filter unique proposed question IDs
    choices <- unique(intermittent$question_id_proposed)
    # Update select input
    updateSelectInput(
      session,
      "intermittent_proposed_link",
      choices = choices
    )
  }
)

# Event handler for creating intermittent links
observeEvent(
  input$intermittent_create_link,
  {
    # Generate intermittent link
    genIntermittentLink(input$intermittent_uqid, input$intermittent_proposed_link, conn, link_conn)
    
    shiny::showModal(
      shiny::modalDialog(
        paste0(
          "Link created between between ", input$intermittent_uqid, " and ", input$intermittent_proposed_link, "!"
        ),
        easyClose = TRUE
      )
    )
    
    # Get unique IDs with intermittent links
    choices <- dbGetQuery(
      link_conn,
      "
      SELECT distinct uqid
      FROM imperfect_link_v
      WHERE intermittent_link = 1
      "
    )$uqid
    # Update select input
    updateSelectInput(
      session,
      "intermittent_uqid",
      choices = choices
    )
  }
)