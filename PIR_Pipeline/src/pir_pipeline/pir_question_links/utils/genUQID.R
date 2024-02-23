#' Generate a unique question ID
#' 
#' `genUQID` checks for a `uqid` column and generates uqids for
#' records without them.
#' @param df A data frame.
#' @returns The input data frame with an updated/generated `uqid` column. 

genUQID <- function(df) {
  
  require(dplyr)
  
  df %>%
    # Generate uqid if it does not exist. 
    {
      if (is.null(.$uqid)) {
        mutate(., uqid = NA_character_)
      } else {
        .
      }
    } %>%
    mutate(
      uqid = case_when(
        is.na(uqid) ~ uuid::UUIDgenerate(n = nrow(.)),
        TRUE ~ uqid
      )
    ) %>%
    assertr::assert(is_uniq, uqid) %>%
    return()
}
