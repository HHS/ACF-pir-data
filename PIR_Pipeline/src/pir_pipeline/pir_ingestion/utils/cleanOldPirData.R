# Deduplicate questions
deduplicate_question <- function(list_of_errors, data) {
  orig_vars <- names(data)
  data %>%
    arrange(pirweb_field_name) %>%
    mutate(
      row = row_number(),
      has_field_name = !is.na(pirweb_field_name),
      sum_has_field_name = sum(has_field_name),
      to_keep = case_when(
        has_field_name == TRUE & sum_has_field_name == 1 ~ TRUE,
        row == 1 ~ TRUE,
        TRUE ~ FALSE
      )
    ) %>%
    filter(to_keep == TRUE) %>%
    mutate(n = n()) %>%
    assertr::verify(n == 1) %>%
    select(all_of(orig_vars)) %>%
    ungroup() %>%
    return()
}

# Move questions to unmatched question table
identifyUnmatched <- function(list_of_errors, data) {
  
  parent_env <- parent.env(environment())
  
  unmatched_question <- data %>%
    filter(merge != 3) %>%
    distinct(question_number, question_name, merge) %>%
    mutate(
      reason = case_when(
        merge == 1 ~ "In response, but not question.",
        merge == 2 ~ "In question, but not response."
      ),
      question_name = ifelse(is.na(question_name), question_number, question_name),
      section_response = NA_character_,
      type = NA_character_
    )
  
  assign("unmatched_question", unmatched_question, parent_env)
  
  data %>%
    filter(merge == 3) %>%
    return()
}

# Merge by only grant and delegate number
grantDelegateMerge <- function(list_of_errors, data) {
  data %>%
    filter(merge == 1) %>%
    select(-c(merge, program_type, program_number)) %>%
    left_join_check(
      program %>%
        select(grant_number, delegate_number, program_number, program_type),
      by = c("grant_number", "delegate_number"),
      relationship = "many-to-one"
    ) %>%
    assertr::verify(any(merge == 3)) %>%
    return()
  
}

loadData <- function(workbooks, log_file) {
  
  workbooks <- purrr::map(
    workbooks,
    function(workbook) {
      sheets <- attr(workbook, "sheets")
      response_list <- list()
      for (sheet in sheets) {
        sheet_lower <- tolower(sheet)
        df <- readxl::read_xlsx(workbook, sheet = sheet)
        if (!grepl("program|datadictionary|grantees", sheet_lower)) {
          try(
            response_list <- df %>%
              assertr::assert_rows(col_concat, assertr::is_uniq, GRNUM, DELNUM) %>%
              {append(response_list, list(.))},
            silent = TRUE
          )
        }
        else if (grepl("program|grantees", sheet_lower)) {
          program <- df %>%
            assertr::assert_rows(assertr::col_concat, assertr::is_uniq, GRNUM, DELNUM)
        }
        else if (grepl("datadictionary", sheet_lower)) {
          question <- df %>%
            janitor::clean_names()
        }
      }
      attr(workbook, "question") <- question
      attr(workbook, "program") <- program
      
      response <- purrr::reduce(
        response_list, 
        function (x, y) {
          df = dplyr::full_join(x, y, by = c("GRNUM", "DELNUM"), relationship = "one-to-one")
          return(df)
        }
      )
      attr(workbook, "response") <- response
      
      return(workbook)
    }
  )
  gc()
  return(workbooks)
}

cleanQuestion <- function(workbooks, log_file) {
  workbooks <- purrr::map(
    workbooks,
    function(workbook) {
      question <- attr(workbook, "question")
      
      question <- question %>%
        group_by(field_name) %>%
        {
          if ("pirweb_field_name" %in% names(question)) {
            distinct(., field_name, pirweb_field_name, description, .keep_all = TRUE)
          } else {
            distinct(., field_name, description, .keep_all = TRUE) %>%
              mutate(
                pirweb_field_name = NA_character_,
                hses_field_type = NA_character_,
                hses_field_name = NA_character_
              )
          }
        } %>%
        mutate(n = n()) %>%
        assertr::verify(n == 1, error_fun = deduplicate_question) %>%
        ungroup()
      
      question <- question %>%
        rename(
          question_text = description,
          type = hses_field_type
        ) %>%
        mutate(
          question_name = coalesce(hses_field_name, pirweb_field_name, question_text),
          question_number = field_name,
          question_number = gsub(
            "(\\w)(\\d{1,2})(\\w)?(\\w)?(\\w)?",
            "\\1.\\2.\\3.\\4-\\5",
            question_number,
            perl = T
          ),
          question_number = gsub("\\W(?=\\W)|\\W$", "", question_number, perl = T),
          question_number = gsub("\\.0(\\d)", ".\\1", question_number, perl = T),
          section_response = NA_character_
        )
      
      attr(workbook, "question") <- question
      return(workbook)
    }
  )
  gc()
  return(workbooks)
}

cleanProgram <- function(workbooks, log_file) {
  workbooks <- purrr::map(
    workbooks,
    function(workbook) {
      question <- attr(workbook, "question")
      program <- attr(workbook, "program")
      
      program_col_names <- lapply(names(program),
        function(x){
          index <- question$field_name == x
          var_name <- question$pirweb_field_name[index]
          if (is.na(var_name)) {
            var_name <- question$hses_field_name[index]
          }
          if (is.null(var_name) || is.na(var_name)) {
            var_name <- question$field_name[index]
          }
          return(var_name)
        }
      )
      
      program <- program %>%
        setNames(program_col_names) %>%
        janitor::clean_names() %>%
        rename_with(
          ~ gsub("pgm", "program", .)
        ) %>%
        {
          if ("sys_hs_program_id" %in% names(.)) {
            .
          } else {
            mutate(., sys_hs_program_id = -1)
          }
        } %>%
        {
          if ("program_zip" %in% names(.)) {
            rename(
              .,
              program_address_line_1 = program_address1,
              program_address_line_2 = program_address2,
              program_main_email = agency_email,
              program_number = sys_hs_program_id,
              grant_number = grantno,
              delegate_number = delegateno,
              program_main_phone_number = program_phone
            )
          } else {
            rename(
              .,
              program_address_line_1 = q05,
              program_address_line_2 = q06,
              program_main_email = q14,
              program_number = sys_hs_program_id,
              grant_number = grnum,
              delegate_number = delnum,
              program_main_phone_number = q10,
              program_zip = q09
            )
          }
        } %>%
        tidyr::separate(
          program_zip,
          c("program_zip_code", "program_zip_4"),
          5
        ) %>%
        assertr::assert_rows(col_concat, is_uniq, grant_number, delegate_number) %>%
        {
          if ("program_type" %in% names(.)) {
            .
          } else {
            mutate(., program_type = "Unknown")
          }
        }
      
      attr(workbook, "program") <- program
      
      return(workbook)
    }
  )
  gc()
  return(workbooks)
}

cleanResponse <- function(workbooks, log_file) {
  workbooks <- purrr::map(
    workbooks,
    function(workbook) {
      response <- attr(workbook, "response")
      question <- attr(workbook, "question")
      program <- attr(workbook, "program")
      
      response <- response %>%
        select(
          -ends_with(c(".y"))
        ) %>%
        rename_with(
          ~ gsub("\\.x", "", ., perl = TRUE), ends_with(".x")
        ) %>%
        select(-starts_with("q")) %>%
        {
          if ("SYS_HS_PROGRAM_ID" %in% names(.)) {
            .
          } else {
            mutate(., SYS_HS_PROGRAM_ID = -1)
          }
        } %>%
        rename(
          grant_number = GRNUM,
          delegate_number = DELNUM,
          program_number = SYS_HS_PROGRAM_ID,
          region = RegionNumber
        ) %>%
        select(
          grant_number, delegate_number, region, program_number, matches("\\w\\d")
        ) %>%
        {
          if (any(!is.na(.$program_number))) {
            assertr::assert_rows(., col_concat, is_uniq, grant_number, delegate_number, program_number)
          } else {
            assertr::assert_rows(., col_concat, is_uniq, grant_number, delegate_number)
          }
        }
      
      program <- program %>%
        left_join_check(
          response %>%
            select(grant_number, delegate_number, region),
          by = c("grant_number", "delegate_number"),
          relationship = "one-to-one"
        ) %>%
        assertr::verify(merge == 3) %>%
        select(-c(merge))
      assign("program", program, envir = .GlobalEnv)
      
      response <- response %>%
        mutate(across(everything(), as.character)) %>%
        pivot_longer(
          -c("grant_number", "delegate_number", "region", "program_number"),
          names_to = "question_number",
          values_to = "answer"
        ) %>%
        mutate(
          delegate_number = as.numeric(delegate_number),
          program_number = as.numeric(program_number),
          question_number = gsub(
            "(\\w)(\\d{1,2})(\\w)?(\\w)?(\\w)?",
            "\\1.\\2.\\3.\\4-\\5",
            question_number,
            perl = T
          ),
          question_number = gsub("\\W(?=\\W)|\\W$", "", question_number, perl = T),
          question_number = gsub("\\.0(\\d)", ".\\1", question_number, perl = T)
        )
      
      response <- response %>%
        left_join_check(
          program %>%
            select(grant_number, delegate_number, program_number, program_type),
          by = c("grant_number", "delegate_number", "program_number"),
          relationship = "many-to-one"
        ) %>%
        assertr::verify(merge %in% c(1, 3)) %>%
        assertr::verify(any(merge == 3), error_fun = grantDelegateMerge) %>%
        filter(merge == 3) %>%
        select(-merge) %>%
        rename(type = program_type) %>%
        left_join_check(
          question %>%
            select(question_number, question_name),
          by = c("question_number"),
          relationship = "many-to-one"
        ) %>%
        assertr::verify(merge == 3, error_fun = identifyUnmatched) %>%
        assertr::assert(not_na, question_name) %>%
        select(-merge)
      
      attr(workbook, "response") <- response
      attr(workbook, "program") <- program
      rm(program, envir = .GlobalEnv)

      if (exists("unmatched_question", environment())) {
        attr(workbook, "unmatched_question") <- unmatched_question
        question <- question %>%
          full_join(
            unmatched_question %>%
              select(question_number, question_name),
            by = c("question_number", "question_name")
          )
        attr(workbook, "question") <- question
        rm(unmatched_question, inherits = TRUE)
      }
      
      return(workbook)
    }
  )
  gc()
  return(workbooks)
}
