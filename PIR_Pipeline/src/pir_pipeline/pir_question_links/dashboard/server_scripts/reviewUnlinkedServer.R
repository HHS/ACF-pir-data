output$unlinked <- function() {
  
  if (input$review_algorithm == "Base") {
  
  unlinked <- dbGetQuery(
    link_conn,
    paste0(
      "call reviewUnlinkedV('", input$review_question_id, "')"
    )
  ) %>%
    mutate(algorithm_dist = "Base")
  
  jaccard <- jaccardIDMatch(link_conn, input$review_question_id, "unlinked")$matches
  
  jaccard <- jaccard %>%
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
        "compare",
        "dist",
        .,
        perl = TRUE
      ),
      ends_with("compare")
    ) %>%
    mutate(
      algorithm = "Weighted Jaccard",
      across(matches("year"), as.character)
    ) %>%
    select(any_of(names(unlinked))) %>%
    mutate(algorithm_dist = "Weighted Jaccard")
  
  unlinked <- bind_rows(
    unlinked,
    jaccard
  ) %>%
    # Replace observations in Jaccard with stored procedure results for base 
    fill(
      question_name, question_text, question_number, section,
      starts_with("base"),
      .direction = "down"
    )
  
  } else {
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
      select(matches(c("question", "section", "year")), ends_with(c("id", "dist"))) %>%
      mutate(algorithm_dist = "Weighted Jaccard")
  }
  
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
  
  unlinked <- left_join(
    base,
    comparison,
    by = "Variable"
  ) %>%
    full_join(
      distances,
      by = "Variable"
    )
  
  unlinked %>%
    kableExtra::kable() %>%
    kableExtra::kable_styling("striped")
}

observeEvent(
  input$review_question_id,
  {
    if (input$review_algorithm == "Base") {
      unlinked <- dbGetQuery(
        link_conn,
        paste0(
          "call reviewUnlinkedV('", input$review_question_id, "')"
        )
      )
      jaccard <- jaccardIDMatch(link_conn, input$review_question_id, "unlinked")$matches
      choices <- unique(c(unlinked$proposed_id, jaccard$question_id_proposed))
    } else {
      choices <- jaccardUnlinked(link_conn, input$review_question_id)$question_id_proposed
    }
    updateSelectInput(
      session,
      "review_proposed_link",
      choices = choices
    )
  }
)

observeEvent(
  input$review_algorithm,
  {
    if (input$review_algorithm == "Base") {
      unlinked <- dbGetQuery(
        link_conn,
        paste0(
          "call reviewUnlinkedV('", input$review_question_id, "')"
        )
      )
      jaccard <- jaccardIDMatch(link_conn, input$review_question_id, "unlinked")$matches
      choices <- unique(c(unlinked$proposed_id, jaccard$question_id_proposed))
    } else {
      choices <- jaccardUnlinked(link_conn, input$review_question_id)$question_id_proposed
    }
    updateSelectInput(
      session,
      "review_proposed_link",
      choices = choices
    )
    
  }
)

observeEvent(
  input$review_create_link,
  {
    genLink(input$review_question_id, input$review_proposed_link, link_conn)
    choices <- dbGetQuery(
      link_conn,
      "
      SELECT distinct question_id
      FROM unlinked;
      "
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