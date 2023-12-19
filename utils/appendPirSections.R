#' Append all "Section" sheets of PIR workbook
#' 
#' `appendPirSections` loads all sheets of a PIR data workbook
#' which contain the word "Section" and appends them. The resultant
#' data frame is returned in a list with name "response".
#' 
#' @param workbook Path to the workbook to load sheets from
#' @returns List of 1 element, response, containing the appended sheets.
#' @examples
#' # example code
#' appendPirSections(test_wb.xlsx)

appendPirSections <- function(workbook) {
  
  to_append <- list()
  func_env <- environment()
  
  sheets <- readxl::excel_sheets(workbook)
  
  # Extract the sheets of interest
  walk(
    sheets,
    function(sheet) {
      if (grepl("Section", sheet)) {
        to_append <- append(to_append, sheet)
        assign("to_append", to_append, envir = func_env)
      }
    }
  )
  
  # Reshape the data
  to_append <- map(
    to_append,
    function(sheet) {
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
        left_join(
          text_df,
          by = c("question_number"),
          relationship = "many-to-one"
        ) %>%
        assert(not_na, question_name)
      
      return(df)
    }
  )
  
  # Append the data
  appended <- bind_rows(to_append)
  return(list("response" = appended))
}