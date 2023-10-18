library(dplyr)
library(tidyr)
library(forcats)
library(stringr)
library(purrr)
library(readr)
library(tibble)
library(ggplot2)

years <- c('2019', '2021', '2022')
path <- here::here('pir-metrics', 'clean', 'output', str_glue('pir_clean_{years[1]}_{years[length(years)]}.csv'))
pir_data <- read_csv(path)

path <- here::here('pir-metrics', 'reporting', 'input', 'region_state_crosswalk.csv')
region_state_crosswalk <- read_csv(path) 

# missingness ----

## from clean task ----
path <- here::here('pir-metrics', 'clean', 'output', 'missing_grants_in_centers_data.csv')
missing_grants_in_centers <- read_csv(path)

missing_centers_cumulative_enrolled_children <- pir_data %>%
  filter(grant_number %in% missing_grants_in_centers$grant_number) %>%
  pull(total_cumulative_enrolled_children) %>%
  sum()
missing_centers_program <- nrow(missing_grants_in_centers)

paste0('There are ', missing_centers_program, ' programs with ', missing_centers_cumulative_enrolled_children, ' enrolled children that cannot be found in the centers data.')

path <- here::here('pir-metrics', 'clean', 'output', 'incorrect_service_locations.csv')
incorrect_service_location <- read_csv(path)

incorrect_service_location_program <- nrow(incorrect_service_location)

paste0('There are ', incorrect_service_location_program, ' programs with service locations that need review.')

path <- here::here('pir-metrics', 'clean', 'output', 'region_mismatch.csv')
region_mismatch <- read_csv(path)

incorrect_region <- region_mismatch %>% 
  filter(str_detect(pir_region, '11|12|13', negate = T)) %>%
  nrow

paste0('There are ', incorrect_region, ' records with incorrect region values.')

## pir values  ----
n_missing_pir_values <- pir_data %>%
  summarize(across(everything(), ~ sum(is.na(.x)))) %>%
  select(where(\(x) x > 0)) %>%
  pivot_longer(cols = everything(), names_to = 'variable', values_to = 'missing_records')

# export ----
rm(path)
save.image(here::here('pir-metrics', 'reporting', 'output', 'reporting.RData'))

rm(list = ls())
