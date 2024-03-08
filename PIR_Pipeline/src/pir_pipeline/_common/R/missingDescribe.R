################################################################################
## Written by: Reggie Gilliard
## Date: 02/23/2024
## Description: Define a function to summarize missing values in a dataframe.
################################################################################


#' Summarize missing values in a data frame.
#' 
#' The `missingDescribe` function calculates the number and percentage of missing values 
#' for each variable in a given data frame. It returns a data frame summarizing the 
#' missing values for each variable.
#' 
#' @param data The input data frame.
#' @param ... Optional arguments specifying variable names to include in the summary.
#' @return A data frame summarizing missing values for each variable.

missingDescribe <- function(data, ...) {
  # Load the dplyr package
  require(dplyr)
  # Capture the function call
  dots <- match.call(expand.dots = F)
  # Extract variable names from the arguments
  names <- paste(dots$...) %>%
    {gsub("\\`", "", .)}
  # Get the number of rows in the data frame
  nrows <- nrow(data)
  # Check if variable names are provided
  if (is.null(dots$...)) {
    # If not, summarize missing values for all variables
    miss <- data %>%
      summarize(across(everything(), ~ sum(is.na(.))))
  } else {
    # If provided, summarize missing values for specified variables
    miss <- data %>%
      summarize(across(all_of(names), ~ sum(is.na(.))))
  }
  # Identify variables that are not group variables (if applicable)
  to_pivot <- names(miss) %in% group_vars(data)
  to_pivot <- !to_pivot
  to_pivot <- names(miss)[to_pivot]
  # Reshape the data frame for better readability
  miss %>%
    tidyr::pivot_longer(cols = all_of(to_pivot), names_to = "Variable", values_to = "n_missing") %>%
    mutate(pct_missing = round(100*n_missing/nrows, 2))
}




