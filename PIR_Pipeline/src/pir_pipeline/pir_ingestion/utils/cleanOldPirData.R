# Deduplicate questions
deduplicate_question <- function(list_of_errors, data) {
  # Original variables
  orig_vars <- names(data)

  data %>%
    arrange(pirweb_field_name) %>%
    # Logic for deduplication
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
  
  # Get calling environment
  parent_env <- parent.env(environment())
  
  # Identify unmatched questions
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
  
  # Assign unmatched questions to parent environment
  assign("unmatched_question", unmatched_question, parent_env)
  
  # Return matched questions
  data %>%
    filter(merge == 3) %>%
    return()
}

# Merge by only grant and delegate number
grantDelegateMerge <- function(list_of_errors, data) {
  #' If program_number doesn't exist in the data or is always NA,
  #' then the merge by grant_number and delegate_number only
  data %>%
    # Keep only records in the response data
    filter(merge == 1) %>%
    select(-c(merge, program_type, program_number)) %>%
    # Merge by grant_number and delegate_number
    left_join_check(
      program %>%
        select(grant_number, delegate_number, program_number, program_type),
      by = c("grant_number", "delegate_number"),
      relationship = "many-to-one"
    ) %>%
    assertr::verify(any(merge == 3)) %>%
    return()
  
}

# Load the PIR data
loadData <- function(workbooks, log_file) {
  
  workbooks <- purrr::map(
    workbooks,
    function(workbook) {
      # Get the sheets from the workbook
      sheets <- attr(workbook, "sheets")
      # Create a list to store the response data
      response_list <- list()
      # Loop through the sheets
      for (sheet in sheets) {
        sheet_lower <- tolower(sheet)
        df <- readxl::read_xlsx(workbook, sheet = sheet)
        # If the sheet does not contain program, datadictionary, or grantees, then consider it a response sheet
        # and check for duplicates on the GRNUM and DELNUM columns. If this check passes, append to the response_list
        if (!grepl("program|datadictionary|grantees", sheet_lower)) {
          try(
            response_list <- df %>%
              assertr::assert_rows(col_concat, assertr::is_uniq, GRNUM, DELNUM) %>%
              {append(response_list, list(.))},
            silent = TRUE
          )
        }
        # If the sheet contains the words program or grantees, consider this a program sheet and check for duplicates
        # on the GRNUM and DELNUM columns. 
        else if (grepl("program|grantees", sheet_lower)) {
          program <- df %>%
            assertr::assert_rows(assertr::col_concat, assertr::is_uniq, GRNUM, DELNUM)
        }
        # If the sheet contains the word datadictionary, consider this a question sheet
        else if (grepl("datadictionary", sheet_lower)) {
          question <- df %>%
            janitor::clean_names()
        }
      }
      # Set the data as attributes of the workbook
      attr(workbook, "question") <- question
      attr(workbook, "program") <- program
      
      # Merge all of the response data into a single dataframe
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

# Clean the question data
cleanQuestion <- function(workbooks, log_file) {
  workbooks <- purrr::map(
    workbooks,
    function(workbook) {
      # Get the question data
      question <- attr(workbook, "question")
      
      question <- question %>%
        group_by(field_name) %>%
        # Handle case where pirweb_field_name is missing
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
          # Generate question name from the available field names and question_text
          question_name = coalesce(hses_field_name, pirweb_field_name, question_text),
          question_number = field_name,
          # Split question number
          question_number = gsub(
            "(\\w)(\\d{1,2})(\\w)?(\\w)?(\\w)?",
            "\\1.\\2.\\3.\\4-\\5",
            question_number,
            perl = T
          ),
          # Remove any trailing non-word characters (i.e. punctuation)
          question_number = gsub("\\W(?=\\W)|\\W$", "", question_number, perl = T),
          # Remove leading 0s in e.g. C.01 -> C.1
          question_number = gsub("\\.0(\\d)", ".\\1", question_number, perl = T),
          section_response = "NA"
        )
      
      attr(workbook, "question") <- question
      return(workbook)
    }
  )
  gc()
  return(workbooks)
}

# Clean program data
cleanProgram <- function(workbooks, log_file) {
  workbooks <- purrr::map(
    workbooks,
    function(workbook) {
      question <- attr(workbook, "question")
      program <- attr(workbook, "program")
      
      # Get the column names from the question data
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
        # Generate sys_hs_program_id if it doesn't exist
        {
          if ("sys_hs_program_id" %in% names(.)) {
            .
          } else {
            mutate(., sys_hs_program_id = -1)
          }
        } %>%
        # Rename columns according to what is present in the data
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
        # Split 9 digit zip code into 5 and 4 digit parts
        tidyr::separate(
          program_zip,
          c("program_zip_code", "program_zip_4"),
          5
        ) %>%
        assertr::assert_rows(col_concat, is_uniq, grant_number, delegate_number) %>%
        # Generate program type if it doesn't exist
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

# Clean response data
cleanResponse <- function(workbooks, log_file) {
  workbooks <- purrr::map(
    workbooks,
    function(workbook) {
      response <- attr(workbook, "response")
      question <- attr(workbook, "question")
      program <- attr(workbook, "program")
      
      response <- response %>%
        # Remove duplicated variables
        select(
          -ends_with(c(".y"))
        ) %>%
        # Remove trailing .x from variable names
        rename_with(
          ~ gsub("\\.x", "", ., perl = TRUE), ends_with(".x")
        ) %>%
        # Remove variables that start with q
        select(-starts_with("q")) %>%
        # Add SYS_HS_PROGRAM_ID if it doesn't exist
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
        # Select only identifying variables and survey questions
        select(
          grant_number, delegate_number, region, program_number, matches("\\w\\d")
        ) %>%
        # Confirm that the data is unique at the appropriate level
        {
          if (any(!is.na(.$program_number))) {
            assertr::assert_rows(., col_concat, is_uniq, grant_number, delegate_number, program_number)
          } else {
            assertr::assert_rows(., col_concat, is_uniq, grant_number, delegate_number)
          }
        }
      
      program <- program %>%
        # Merge region on to program data
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
        # Reshape response data
        pivot_longer(
          -c("grant_number", "delegate_number", "region", "program_number"),
          names_to = "question_number",
          values_to = "answer"
        ) %>%
        mutate(
          delegate_number = as.numeric(delegate_number),
          program_number = as.numeric(program_number),
          # Generate question_number
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
        # Add program type
        left_join_check(
          program %>%
            select(grant_number, delegate_number, program_number, program_type),
          by = c("grant_number", "delegate_number", "program_number"),
          relationship = "many-to-one"
        ) %>%
        assertr::verify(merge %in% c(1, 3)) %>%
        # Confirm that at least one record merges, if not, conduct merge again without program_number
        assertr::verify(any(merge == 3), error_fun = grantDelegateMerge) %>%
        filter(merge == 3) %>%
        select(-merge) %>%
        rename(type = program_type) %>%
        # Add question name
        left_join_check(
          question %>%
            select(question_number, question_name),
          by = c("question_number"),
          relationship = "many-to-one"
        ) %>%
        # Identify any unmatched questions
        assertr::verify(merge == 3, error_fun = identifyUnmatched) %>%
        assertr::assert(not_na, question_name) %>%
        select(-merge)
      
      # Update workbook attributes
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
