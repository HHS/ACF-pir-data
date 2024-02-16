missingDescribe <- function(data, ...) {
  dots <- match.call(expand.dots = F)
  names <- paste(dots$...) %>%
    {gsub("\\`", "", .)}
  nrows <- nrow(data)
  if (is.null(dots$...)) {
    miss <- data %>%
      summarize(across(everything(), ~ sum(is.na(.))))
  } else {
    miss <- data %>%
      summarize(across(all_of(names), ~ sum(is.na(.))))
  }
  
  to_pivot <- names(miss) %in% group_vars(data)
  to_pivot <- !to_pivot
  to_pivot <- names(miss)[to_pivot]
  
  miss %>%
    tidyr::pivot_longer(cols = all_of(to_pivot), names_to = "Variable", values_to = "n_missing") %>%
    mutate(pct_missing = round(100*n_missing/nrows, 2))
}
