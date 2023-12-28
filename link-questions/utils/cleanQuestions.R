cleanQuestions <- function(df_list) {
  pkgs <- c("uuid", "assertr", "stringr", "rlang", "jsonlite", "tidyr", "dplyr")
  invisible(sapply(pkgs, require, character.only = T))
  
  # Separate data
  if (!is.null(df_list$linked)) {
    linked <- df_list$linked %>%
      select(
        matches(attr(., "db_vars")), -matches(c("dist", "subsection"))
      )
  } else {
    linked <- NULL
  }
  confirmed <- df_list$confirmed
  unconfirmed <- df_list$unconfirmed
  linked_db <- df_list$linked_db %>%
    rename(id_matching = question_id) %>%
    distinct(uqid, id_matching)
  
  # Query extant linked db
  years <- list(
    attr(df_list$unconfirmed, "years"), 
    attr(df_list$linked, "years"), 
    attr(df_list$confirmed, "years")
  )
  years <- years[map_lgl(years, ~ !is.null(.x))]
  years <- first(years)
  min_yr <- min(years)
  max_yr <- max(years)
  
  if (nrow(linked_db) == 0) {

    stopifnot(is.null(linked))
    
    linked <- confirmed %>%
      mutate(uqid = uuid::UUIDgenerate(n = nrow(.))) %>%
      assert(is_uniq, uqid) %>%
      select(matches(attr(., "db_vars")), -matches(c("year", "dist", "subsection"))) %>%
      pivot_longer(
        !c(uqid),
        names_to = c(".value", "year"),
        names_pattern = "^(\\w+)(\\d{4})$"
      ) %>%
      mutate(year = as.numeric(year))
      
    
  } else if (is.null(confirmed) || nrow(confirmed) == 0) {
    
    linked %>%
      assert_rows(col_concat, is_uniq, uqid, year) %>%
      assert_rows(col_concat, is_uniq, question_id, year)
    
  } else {
    
    min_yr_id <- paste0("question_id", min_yr)
    max_yr_id <- paste0("question_id", max_yr)

    linked <- confirmed %>%
      # Merge to lower year first
      mutate(id_matching = !!sym(min_yr_id)) %>%
      left_join(
        linked_db,
        by = "id_matching",
        relationship = "one-to-one"
      ) %>%
      # Update with upper year if uqid is missing
      mutate(id_matching = !!sym(max_yr_id)) %>%
      left_join(
        linked_db %>%
          rename(update_id = uqid),
        by = "id_matching",
        relationship = "one-to-one"
      ) %>%
      mutate(
        uqid = ifelse(is.na(uqid) & !is.na(update_id), update_id, uqid),
        uqid = case_when(
          is.na(uqid) ~ UUIDgenerate(n = nrow(.)),
          TRUE ~ uqid
        )
      ) %>%
      assert(is_uniq, uqid) %>%
      select(matches(attr(., "db_vars")), -matches(c("year", "dist", "subsection"))) %>%
      pivot_longer(
        !c(uqid),
        names_to = c(".value", "year"),
        names_pattern = "^(\\w+)(\\d{4})$"
      ) %>%
      mutate(year = as.numeric(year)) %>%
      assert(not_na, question_id) %>%
      bind_rows(linked) %>%
      assert_rows(col_concat, is_uniq, uqid, year) %>%
      assert_rows(col_concat, is_uniq, question_id, year)

  }
  
  if (!is.null(unconfirmed)) {
    unlinked <- unconfirmed %>%
      nest(distances = ends_with("dist")) %>%
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
                mutate(
                  ., 
                  !!proposed_var := !!sym(paste(id_var)),
                  !!proposed_var := setNames(distances, !!sym(proposed_var))
                ) %>%
                  select(all_of(proposed_var))
              }
            )
          )
        )
      } %>%
      select(matches(attr(unconfirmed, "db_vars")), -matches(c("year", "dist", "subsection"))) %>%
      pivot_longer(
        everything(),
        names_to = c(".value", "year"),
        names_pattern = "^(\\w+)(\\d{4})$"
      ) %>%
      mutate(year = as.numeric(year)) %>%
      group_by(question_id, year) %>%
      mutate(proposed_link = jsonlite::toJSON(proposed_link)) %>%
      ungroup() %>%
      distinct(year, question_id, .keep_all = T) %>%
      assert_rows(
        col_concat,
        is_uniq,
        year, question_id
      )
  } else {
    unlinked <- NULL
  }
  
  return(
    list("linked" = linked, "unlinked" = unlinked)
  )
}

