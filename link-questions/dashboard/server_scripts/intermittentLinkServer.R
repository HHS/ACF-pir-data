output$intermittent_link <- function() {
  
  intermittent <- intermittentIDMatch(link_conn, input$intermittent_uqid)$matches
  
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
    pivot_longer(
      -c(id, name),
      names_to = "column"
    ) %>%
    pivot_wider(
      names_from = c("id", "name"),
      values_from = value,
      names_glue = "{name}_{id}"
    ) 
  
  
  intermittent %>%
    kableExtra::kable() %>%
    kableExtra::kable_styling("striped")
}

observeEvent(
  input$intermittent_uqid,
  {
    intermittent <- intermittentIDMatch(link_conn, input$intermittent_uqid)$matches
    
    choices <- unique(intermittent$question_id_proposed)
    updateSelectInput(
      session,
      "intermittent_proposed_link",
      choices = choices
    )
  }
)

observeEvent(
  input$intermittent_create_link,
  {
    genIntermittentLink(input$intermittent_uqid, input$intermittent_proposed_link, conn, link_conn)
    updateSelectInput(
      session,
      "intermittent_uqid",
      choices = dash_meta$intermittent_uqid_choices,
      selected = "None"
    )
    js$refresh_page()
  }
)