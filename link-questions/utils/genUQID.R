genUQID <- function(df) {
  df %>%
    {
      if (is.null(.$uqid)) {
        mutate(., uqid = NA_character_)
      } else {
        .
      }
    } %>%
    mutate(
      uqid = case_when(
        is.na(uqid) ~ UUIDgenerate(n = nrow(.)),
        TRUE ~ uqid
      )
    ) %>%
    assert(is_uniq, uqid) %>%
    return()
}
