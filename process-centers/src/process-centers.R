library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(readr)
library(tibble)
library(readxl)

# agency data ----
path <- here::here('process-centers', 'input', 'Agency List.xlsx')
agencies <- read_excel(path) %>%
  janitor::clean_names()

# centers data ----
path <- here::here('process-centers', 'input', 'Centers-5-17-19.xlsx')
centers19 <- read_excel(path, sheet = 'Centers by Program') %>%
  janitor::clean_names()

path <- here::here('process-centers', 'input', 'Centers-2-24-20.xlsx')
centers20 <- read_excel(path, sheet = 'Centers by Program') %>%
  janitor::clean_names()

path <- here::here('process-centers', 'input', 'Head Start Centers Data Request-1-13-22 - OPRE.xlsx')
centers21 <- read_excel(path, sheet = 'Centers Data-12-21-21') %>%
  janitor::clean_names()

path <- here::here('process-centers', 'input', 'Centers Archive-10-10-22.xlsx')
centers22 <- read_excel(path, sheet = 'Centers by Program') %>%
  janitor::clean_names()

# Cleaning  ----
agencies <- agencies %>%
  select(-x12)

centers19 <- centers19 %>%
  select(grant_number, program_type, program_number, state, total_slots) %>%
  mutate(year = '2019')

centers20 <- centers20 %>%
  select(grant_number, program_type, program_number, state, total_slots) %>%
  mutate(year = '2020')

centers21 <- centers21 %>%
  select(grant_number, program_type, program_number, state, total_slots) %>%
  mutate(year = '2021')

centers22 <- centers22 %>%
  select(grant_number, program_type, program_number, state, total_slots) %>%
  mutate(year = '2022')

# add agency_id to centers data ----
agencies <- agencies %>%
  select(agency_id, agency_name, agency_duns, grant_number, grantee_name, contains('period'))

centers_19_22 <- list(centers19, centers20, centers21, centers22) %>%
  map(\(x) left_join(x, agencies, by = 'grant_number', suffix = c('_agency', '_center'))) %>%
  reduce(bind_rows)

# calculate program data by grant number ----
centers_calculated <- centers_19_22 %>%
  select(grant_number, agency_id, state, program_type, program_number, total_slots) %>%
  count(grant_number, state, program_number, program_type, wt = total_slots, name = 'total_slots') %>%
  group_by(grant_number, program_number, program_type) %>%
  mutate(
    pct_slots = total_slots / sum(total_slots),
    states_abbr = paste(state, collapse = ', '), 
    states = n(),
    multi_state = ifelse(states > 1, T, F)
  )

## Record of observation is the grant-program 
enrollment_distribution <- centers_calculated %>% 
  select(grant_number, program_number, state, program_type, total_slots, pct_slots)

## Record of observation is the grant_number 
multi_state_flag <- centers_calculated %>%
  distinct(grant_number, program_number, program_type, multi_state, states_abbr, states)

# export ----
path <- here::here('process-centers', 'output', 'enrollment_by_grant.csv')
write_csv(enrollment_distribution, path)

path <- here::here('process-centers', 'output', 'grants_by_state.csv')
write_csv(multi_state_flag ,path)

rm(list = ls())
