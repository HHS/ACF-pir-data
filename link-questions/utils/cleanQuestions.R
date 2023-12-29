cleanQuestions <- function(df_list) {
  pkgs <- c("uuid", "assertr", "stringr", "rlang", "jsonlite", "tidyr", "dplyr")
  invisible(sapply(pkgs, require, character.only = T))
  
  linked_vars <- df_list$linked_vars
  unlinked_vars <- df_list$unlinked_vars
  
  # Separate data
  if (!is.null(df_list$linked)) {
    linked <- df_list$linked %>%
      select(
        matches(linked_vars), -matches(c("dist", "subsection"))
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
  lower_year <- df_list$lower_year
  upper_year <- df_list$upper_year
  
  lower <- unique(lower_year$year)
  upper <- unique(upper_year$year)
  years <- c(lower, upper)

  min_yr <- min(years)
  max_yr <- max(years)
  
  if (nrow(linked_db) == 0) {

    stopifnot(is.null(linked))
    
    linked <- confirmed %>%
      mutate(uqid = uuid::UUIDgenerate(n = nrow(.))) %>%
      assert(is_uniq, uqid) %>%
      select(matches(linked_vars), -matches(c("year", "dist", "subsection"))) %>%
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
      select(matches(unlinked_vars), -matches(c("year", "dist", "subsection"))) %>%
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

