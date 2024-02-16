#' Load "Section [A-D]" worksheets from PIR workbooks.
#' 
#' `loadPirSection` loads section worksheets from PIR workbooks,
#' transforming the data so that question names are retained.
#' @param workbook A single workbook path.
#' @param sheet The sheet to be ingested.
#' @returns A data frame.

loadPirSection <- function(workbook, sheet) {
  require(dplyr)
  # Do not load colnames. Extract text and colnames below
  df <- readxl::read_excel(workbook, sheet = sheet, col_names = F)
  
  # Name columns using the second row of df
  names(df) <- df[2, ] %>%
    pivot_longer(
      everything(),
      names_to = "variable",
      values_to = "question_number"
    ) %>%
    group_by(question_number) %>%
    mutate(
      num = row_number()
    ) %>%
    ungroup() %>%
    mutate(
      na_number = grepl(
        "^na$",
        tolower(gsub("\\W", "", question_number, perl = T))
      ),
      question_number = ifelse(num != 1, paste(question_number, num, sep = "_"), question_number)
    ) %>%
    pipeExpr(
      assign("na_number", which(.$na_number == TRUE), envir = .GlobalEnv)
    ) %>%
    {.[["question_number"]]}
  
  # First row contains question_name
  text_df <- df[1,] %>%
    pivot_longer(
      cols = everything(),
      names_to = "question_number",
      values_to = "question_name"
    ) %>%
    mutate(
      q_num_lower = trimws(tolower(question_number)),
      q_num_lower = gsub("\\W|_\\d+$", "", q_num_lower, perl = T)
    ) %>%
    filter(
      !is.na(question_name)
    ) %>%
    select(-c(q_num_lower))
  
  df <- df[3:nrow(df),]
  
  df <- df %>% 
    mutate(across(everything(), as.character)) %>%
    pivot_longer(
      cols = !c(
        "Region", "State", "Grant Number", "Program Number", 
        "Type", "Grantee", "Program", "City", "ZIP Code", "ZIP 4"
      ),
      names_to = "question_number",
      values_to = "answer"
    ) %>%
    filter(!is.na(`Grant Number`)) %>%
    # Merge question name
    left_join(
      text_df,
      by = c("question_number"),
      relationship = "many-to-one"
    ) %>%
    assertr::assert(not_na, question_name) %>%
    mutate(section_response = gsub("^Section (\\w)", "\\1", sheet, perl = TRUE))
  
  return(df)
}