################################################################################
## Written by: Reggie Gilliard
## Date: 01/10/2024
## Description: Script to fetch data for the Unlinked questions tab.
################################################################################


# Fetch data for the Unlinked questions tab
output$unlinked <- function() {
  # Check the selected algorithm
  if (input$review_algorithm == "Base") {
    # Execute the review unlinked query for the base algorithm
    unlinked <- dbGetQuery(
      link_conn,
      paste0(
        "call reviewUnlinked('", input$review_question_id, "')"
      )
    )
  } else {
    # Execute the Jaccard unlinked algorithm
    unlinked <- jaccardUnlinked(link_conn, input$review_question_id) %>%
      rename(
        question_id = question_id_base,
        proposed_id = question_id_proposed
      ) %>%
      rename_with(
        ~ gsub(
          "(\\w+)_proposed",
          "comparison_\\1",
          .,
          perl = TRUE
        ),
        ends_with("proposed")
      ) %>%
      rename_with(
        ~ gsub(
          "(\\w+)_base",
          "base_\\1",
          .,
          perl = TRUE
        ),
        ends_with("base")
      ) %>%
      rename_with(
        ~ gsub(
          "compare|score",
          "dist",
          .,
          perl = TRUE
        ),
        ends_with(c("compare", "score"))
      ) %>%
      mutate(
        algorithm = "Weighted Jaccard",
        across(matches("year"), as.character)
      ) %>%
      select(matches(c("question", "section", "year")), ends_with(c("id", "dist")))
  }
  # Prepare base data
  base <- unlinked %>%
    mutate(
      across(everything(), as.character),
      id = row_number()
    ) %>%
    select(question_id, starts_with("base")) %>%
    pivot_longer(
      everything(),
      names_to = "Variable",
      values_to = "Base"
    ) %>%
    distinct() %>%
    mutate(Variable = gsub("base_", "", Variable))
  # Prepare comparison data
  comparison <- unlinked %>%
    mutate(
      id = row_number(),
      across(everything(), as.character)
    ) %>%
    select(starts_with("comparison"), proposed_id, id) %>%
    pivot_longer(
      -id,
      names_to = "Variable"
    ) %>%
    pivot_wider(
      names_from = id,
      values_from = value,
      names_glue = "Proposed {.name}"
    ) %>%
    mutate(
      Variable = str_replace_all(Variable, c("comparison_" = "", "proposed_" = "question_"))
    )
  # Prepare distances data
  distances <- unlinked %>%
    mutate(
      id = row_number(),
      across(everything(), as.character)
    ) %>%
    select(ends_with("dist"), id) %>%
    pivot_longer(
      -id,
      names_to = "Variable"
    ) %>%
    pivot_wider(
      names_from = id,
      values_from = value,
      names_glue = "Distance {.name}"
    ) %>%
    mutate(
      Variable = str_replace_all(Variable, c("_dist" = ""))
    )
  # Join all prepared data
  unlinked <- left_join(
    base,
    comparison,
    by = "Variable"
  ) %>%
    full_join(
      distances,
      by = "Variable"
    )
  # Render the unlinked data as a table
  unlinked %>%
    kableExtra::kable() %>%
    kableExtra::kable_styling("striped")
}
# Observe changes in the review question ID input
observeEvent(
  input$review_question_id,
  {
    if (input$review_algorithm == "Base") {
      # If base algorithm selected, fetch unique proposed IDs from review unlinked query
      unlinked <- dbGetQuery(
        link_conn,
        paste0(
          "call reviewUnlinked('", input$review_question_id, "')"
        )
      )
      choices <- unique(c(unlinked$proposed_id))
    } else {
      # If weighted Jaccard algorithm selected, fetch unique proposed IDs from Jaccard unlinked query
      choices <- jaccardUnlinked(link_conn, input$review_question_id)$question_id_proposed
    }
    # Update select input with available choices for proposed link
    updateSelectInput(
      session,
      "review_proposed_link",
      choices = choices
    )
  }
)

# Observe changes in the review algorithm input
observeEvent(
  input$review_algorithm,
  {
    if (input$review_algorithm == "Base") {
      # If base algorithm selected, fetch unique proposed IDs from review unlinked query
      unlinked <- dbGetQuery(
        link_conn,
        paste0(
          "call reviewUnlinked('", input$review_question_id, "')"
        )
      )
      choices <- unique(c(unlinked$proposed_id))
    } else {
      # If weighted Jaccard algorithm selected, fetch unique proposed IDs from Jaccard unlinked query
      choices <- jaccardUnlinked(link_conn, input$review_question_id)$question_id_proposed
    }
    # Update select input with available choices for proposed link
    updateSelectInput(
      session,
      "review_proposed_link",
      choices = choices
    )
    
  }
)

# Observe creation of a new link
observeEvent(
  input$review_create_link,
  {
    # Generate link based on selected review question ID and proposed link
    genLink(input$review_question_id, input$review_proposed_link, link_conn)
    # Fetch distinct question IDs for unlinked data
    choices <- dbGetQuery(
      link_conn,
      "
      SELECT distinct question_id
      FROM unlinked;
      "
    )
    shiny::showModal(
      shiny::modalDialog(
        paste0(
          "Link created between ", input$review_question_id, " and ", input$review_proposed_link, "!"
        ),
        easyClose = TRUE
      )
    )
    updateSelectInput(
      session,
      "review_question_id",
      choices = choices,
      selected = "None"
    )
    updateSelectInput(
      session,
      "review_proposed_link",
      choices = "None"
    )
  }
)