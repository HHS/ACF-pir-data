library(tidyverse)

`%nin%` = Negate(`%in%`)

# import from /pir-metrics/import/output ----
year <- c('2019', '2021', '2022')
path <- here::here('pir-metrics', 'import', 'output', str_glue('pir_{year[1]}_{year[length(year)]}.csv'))

id_cols <- c('region', 'year', 'state', 'grant_number', 'program_number', 'type', 'grantee', 'program', 'city', 'zip_code', 'zip_4')
program_cols <- c('region', 'grant_number', 'program_number', 'program_type', 'grantee_name', 'program_name', 'program_address_line_1', 'program_address_line_2')
age_cols <- c('less_than_1_year_old', 'x1_year_old', 'x2_years_old', 'x3_years_old', 'x4_years_old', 'x5_years_and_older')

import_data <- read_csv(path)

# import from /process-centers/output ----
path <- here::here('process-centers', 'output', 'grants_by_state.csv')
service_location_check_table <- read_csv(path)

path <- here::here('process-centers', 'output', 'enrollment_by_grant.csv')
enrollment_data <- read_csv(path)

# Remove agencies that don't report relevant data ----
clean_data <- import_data %>%
  filter(program_agency_description %nin% c('Grantee that maintains central office staff only and operates no program(s) directly', 
                                            'Grantee that delegates all of its programs; it operates no programs directly and maintains no central office staff')) 

# turnover ----
clean_data <- clean_data %>%
  mutate(
    total_departed_staff = ifelse(is.na(total_departed_staff),
                                  total_departed_hs_staff + total_departed_contracted_staff,
                                  total_departed_staff),
    across(-c(any_of(id_cols), starts_with('program'), 'total_departed_teachers'), 
           \(x) ifelse(is.na(x), 0, x))
  )

# demographic values ----
clean_data <- clean_data %>% 
  rename_with(.fn = \(x) str_remove(x, '_non_hispanic_or_non_latino_origin')) %>%
  rowwise %>% 
  mutate(hispanic_or_latino_origin = sum(c_across(ends_with('hispanic_or_latino_origin'))), .after = american_indian_alaska_native) %>%
  ungroup %>%
  select(-ends_with('_hispanic_or_latino_origin'))

# total children ----
clean_data <- clean_data %>%
  mutate(total_cumulative_enrolled_children = total_cumulative_enrollment - pregnant_women, .after = pregnant_women)

# service location (state col) ----

## join centers data to pir import ----
service_locations <- clean_data %>% 
  distinct(state, grant_number, type, year)

service_locations <- left_join(service_locations, service_location_check_table, by = c('grant_number', 'type' = 'program_type'))

missing_grants_in_centers_data <- service_locations %>%
  filter(if_any(any_of(c('multi_state', 'states_abbr', 'states')), is.na)) %>%
  select(state, grant_number, type, year)

## flag multi-state grants and incorrect service locations ----
incorrect_service_location <- left_join(
  clean_data,
  service_location_check_table,
  by = c('grant_number', 'type' = 'program_type')
) %>%
  filter(multi_state | states_abbr != state) %>%
  select(region, state, states_abbr, multi_state, grant_number, type)

# export ----
path <- here::here('pir-metrics', 'clean', 'output', str_glue('pir_clean_{year[1]}_{year[length(year)]}.csv'))
write_csv(clean_data, path)

path <- here::here('pir-metrics', 'clean', 'output', 'incorrect_service_locations.csv')
write_csv(incorrect_service_location, path)

path <- here::here('pir-metrics', 'clean', 'output', 'missing_grants_in_centers_data.csv')
write_csv(missing_grants_in_centers_data, path)

rm(list = ls())

