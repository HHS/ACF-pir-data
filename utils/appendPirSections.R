# Append sheets of the PIR data which include responses
appendPirSections <- function(workbook, sheets) {
  
  to_append <- list()
  func_env <- environment()
  
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
          question_number = ifelse(num != 1, paste(question_number, num, sep = "_"), question_number)
        ) %>%
        {.[["question_number"]]}
      
      text_df <- df[1,] %>%
        pivot_longer(
          cols = everything(),
          names_to = "question_number",
          values_to = "question_name"
        ) %>%
        filter(!is.na(question_name))
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
        filter(!is.na(`Grant Number`))
      
      attr(df, "text_df") <- text_df
      return(df)
    }
  )
  
  # Append the data
  appended <- bind_rows(to_append)
  text_list <- map(to_append, ~ attr(., "text_df"))
  attr(appended, "text_df") <- bind_rows(text_list)
  return(appended)
}