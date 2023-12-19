cleanPirData <- function(df_list, schema, yr) {
  
  addPirVars <- function(list_of_errors, data) {
    for (v in mi_vars) {
      data[v] <- NA_character_
    }
    return(data)
  }
  
  func_env <- environment()
  
  walk(
    names(schema),
    function(table) {
      assign(
        paste0(tolower(table), "_vars"),
        schema[[table]],
        envir = func_env
      )
    }
  )
  
  # Remove data frames with 0 observations
  df_list <- df_list[map_lgl(df_list, function(x) nrow(x) > 0)]
  tables <- names(df_list)
  
  # Clean response table data
  response_tables <- tables[grepl("response", tables)]
  walk(
    response_tables,
    function(table) {
      vars <- get(paste0(tolower(table), "_vars"), envir = func_env)
      df_list[[table]] <- df_list[[table]] %>%
        janitor::clean_names() %>%
        rename(
          program_type = type
        ) %>%
        assertr::assert(not_na, grant_number, program_number, program_type) %>%
        assertr::assert(not_na, question_number, question_name) %>%
        mutate(
          year = yr,
          uid_hash = paste0(grant_number, program_number, program_type),
          uid = hashVector(uid_hash),
          question_id_hash = paste0(question_number, question_name),
          question_id = hashVector(question_id_hash)
        ) %>%
        select(all_of(vars))
      assign("df_list", df_list, envir = func_env)
      gc()
    }
  )
  
  # Clean question table data
  question_tables <- tables[grepl("question", tables)]
  walk(
    question_tables,
    function(table) {
      vars <- get(paste0(tolower(table), "_vars"), envir = func_env)
      df_list[[table]] <- df_list[[table]] %>%
        assertr::assert(not_na, question_number, question_name) %>%
        mutate(
          section = gsub("^(\\w).*", "\\1", question_number, perl = T)
        ) %>%
        rename(
          question_type = type
        ) %>%
        mutate(
          year = yr,
          question_id_hash = paste0(question_number, question_name),
          question_id = hashVector(question_id_hash)
        ) %>%
        pipeExpr(
          assign(
            "mi_vars",
            setdiff(question_vars, names(.)),
            envir = func_env
          )
        ) %>%
        assertr::verify(
          length(mi_vars) == 0,
          error_fun = addPirVars
        ) %>%
        select(all_of(vars))
      assign("df_list", df_list, envir = func_env)
      gc()
    }
  )
  
  df_list$program <- df_list$program %>%
    janitor::clean_names() %>%
    assertr::assert(not_na, grant_number, program_number, program_type) %>%
    rename(
      program_zip1 = program_zip_code,
      program_zip2 = program_zip_4,
      program_phone = program_main_phone_number,
      program_email = program_main_email
    ) %>%
    mutate(
      year = yr,
      uid_hash = paste0(grant_number, program_number, program_type),
      uid = hashVector(uid_hash)
    ) %>%
    pipeExpr(
      assign(
        "mi_vars",
        setdiff(program_vars, names(.)),
        envir = func_env
      )
    ) %>%
    assertr::verify(
      length(mi_vars) == 0,
      error_fun = addPirVars
    ) %>%
    select(all_of(program_vars))
  
  return(df_list)
}
