unconfirmedLink <- function(list_of_errors, data) {
  error_df <- list_of_errors[[1]]$error_df
  column <- unique(error_df$column)
  values <- unique(error_df$value)
  data %>%
    mutate(
      confirmed = ifelse(
        !!sym(paste(column)) %in% values,
        0,
        confirmed
      )
    ) %>%
    return()
}