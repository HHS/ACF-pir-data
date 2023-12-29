`%notin%` <- Negate(`%in%`)

merge_check <- function(df) {
  
  df %>%
    mutate(
      merge = case_when(
        merge.x == 1 & merge.y == 1 ~ 3,
        merge.x == 1 & is.na(merge.y) ~ 1,
        is.na(merge.x) & merge.y == 1 ~ 2
      )
    ) %>%
    select(-c("merge.x", "merge.y"))
  
}

full_join_check <- function(x, y, by = NULL, tab = F, verify = NULL, ...) {
  
  df <- full_join(
    mutate(x, merge = 1), 
    mutate(y, merge = 1), 
    by = by, ...
  ) %>%
    merge_check()
  
  # if (tab == T) {
  #   df %>%
  #     tablist(merge)
  # }
  
  if (!is.null(verify)) {
    if (all(is.character(verify))) {
      warning('verify must be numeric')
    } else if (all(verify %notin% c(1, 2, 3))) {
      warning('verify uses stata syntax: 1 = master, 2 = using, 3 = merged')
    }
    
    stopifnot(all(unique(df$merge) %in% c(verify)))
  }
  
  return(df)
  
}

inner_join_check <- function(x, y, by = NULL, tab = F, verify = NULL, ...) {
  
  df <- full_join_check(x, y, by, tab = tab, verify = verify, ...) %>%
    filter(merge == 3)
  
  return(df)
  
}

left_join_check <- function(x, y, by = NULL, tab = F, verify = NULL, ...) {
  
  df <- full_join_check(x, y, by, tab = tab, verify = verify, ...) %>%
    filter(merge %in% c(1, 3))
  
  return(df)
  
}

right_join_check <- function(x, y, by = NULL, tab = F, verify = NULL, ...) {
  
  df <- full_join_check(x, y, by, tab = tab, verify = verify, ...) %>%
    filter(merge %in% c(2, 3))
  
  return(df)
  
}