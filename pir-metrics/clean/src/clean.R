library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(readr)
library(tibble)
library(readxl)

`%nin%` <- Negate(`%in%`)
years <- c('2019', '2021', '2022')
id_cols <- c('region', 'state', 'year', 'grant_number', 'grant_type', 'program_number', 'program_type', 'grantee', 'program', 'city', 'zip_code', 'zip_4')
age_and_pregnant_cols <- c(
  'less_than_1_year_old',
  'x1_year_old',
  'x2_years_old',
  'x3_years_old',
  'x4_years_old',
  'x5_years_and_older',
  'pregnant_women'
)

# import from /pir-metrics/import/output ----
path <- here::here('pir-metrics', 'import', 'output', str_glue('pir_{years[1]}_{years[length(years)]}.csv'))
import_data <- read_csv(path)

# import region-state crosswalk ----
# written based off of https://www.acf.hhs.gov/oro/regional-offices
path <- here::here('pir-metrics', 'clean', 'input', 'region_state_crosswalk.csv')
region_state_crosswalk <- read_csv(path)

# import from /process-centers/output ----
path <- here::here('process-centers', 'output', 'grants_by_state.csv')
service_location_check_table <- read_csv(path)

path <- here::here('process-centers', 'output', 'enrollment_by_grant.csv')
enrollment_data <- read_csv(path)

# remove agencies that don't report relevant data ----
agencies_filtered <- import_data %>%
  filter(program_agency_description %nin% c('Grantee that maintains central office staff only and operates no program(s) directly', 
                                            'Grantee that delegates all of its programs; it operates no programs directly and maintains no central office staff'))

# impute age and pregnant people counts ----
## EHS programs don't serve ages 4 or 5 and older, HS programs don't serve pregnant people
ages_imputed <- agencies_filtered %>%
  mutate(across(all_of(age_and_pregnant_cols), \(x) ifelse(is.na(x), 0, x)))

# turnover ----
turnover <- ages_imputed %>%
  mutate(
    total_departed_staff = ifelse(is.na(total_departed_staff),
                                  total_departed_hs_staff + total_departed_contracted_staff,
                                  total_departed_staff)
  )

# demographic values ----

## this value should equal the sum of the col created in the next step
check_value <- turnover %>%
  summarize(across(ends_with('hispanic_or_latino_origin'), \(x) sum(x, na.rm = T))) %>%
  mutate(check = rowSums(across(everything()))) %>%
  pull(check)

race_eth_summed <- turnover %>% 
  rename_with(.fn = \(x) str_remove(x, '_non_hispanic_or_non_latino_origin')) %>%
  mutate(hispanic_or_latino_origin = rowSums(across((ends_with('hispanic_or_latino_origin'))), na.rm = T), .after = american_indian_alaska_native) %>%
  select(-ends_with('_hispanic_or_latino_origin'))

if ( !
     race_eth_summed %>%
     summarize(check = sum(hispanic_or_latino_origin)) %>%
     pull(check) %>% 
     `==`(check_value)
) warning('Summed hispanic_or_latino_origin values do not match.')

# credentials ----
# This is not a robust solution to fixing these columns, will need to be revisited
consolidate_cols_at_selection <- function(group, sel, consolidated_var, ...) {
  x <- list(...) %>%
    reduce(`+`)
  ifelse(group == sel,
         x,
         consolidated_var)
}

credentials_normalized <- race_eth_summed %>%
  mutate(
    year,
    # 2019 needs to have values summed to individual degree attainment values
    ## HS
    advanced_degree_classroom_teachers = consolidate_cols_at_selection(year, '2019', advanced_degree_classroom_teachers,
                                                                       advanced_degree_in_ece_preschool_classroom_teachers, advanced_degree_in_any_related_field_preschool_classroom_teachers),
    
    baccalaureate_degree_classroom_teachers = consolidate_cols_at_selection(year, '2019', baccalaureate_degree_classroom_teachers,
                                                                            baccalaureate_degree_in_ece_preschool_classroom_teachers, baccalaureate_degree_in_any_related_field_preschool_classroom_teachers, baccalaureate_degree_with_teach_for_america_preschool_classroom_teachers),
    
    associate_degree_classroom_teachers = consolidate_cols_at_selection(year, '2019', associate_degree_classroom_teachers,
                                                                        associate_degree_in_ece_preschool_classroom_teachers, associate_degree_in_any_related_field_preschool_classroom_teachers),
    ## EHS
    advanced_degree_infant_and_toddler_classroom_teachers = consolidate_cols_at_selection(year, '2019', advanced_degree_infant_and_toddler_classroom_teachers,
                                                                                          advanced_degree_in_ece_infant_and_toddler_classroom_teachers, advanced_degree_in_any_related_field_infant_and_toddler_classroom_teachers),
   
    baccalaureate_degree_infant_and_toddler_classroom_teachers = consolidate_cols_at_selection(year, '2019', baccalaureate_degree_infant_and_toddler_classroom_teachers,
                                                                        baccalaureate_degree_in_ece_infant_and_toddler_classroom_teachers, baccalaureate_degree_in_any_related_field_infant_and_toddler_classroom_teachers),
    
    associate_degree_infant_and_toddler_classroom_teachers = consolidate_cols_at_selection(year, '2019', associate_degree_infant_and_toddler_classroom_teachers,
                                                                                           associate_degree_in_ece_infant_and_toddler_classroom_teachers, associate_degree_in_any_related_field_infant_and_toddler_classroom_teachers),
    # NA values replaced by 0 where there are not IT or PreK teachers (no advanced degree EHS teachers at HS programs)
    .keep = 'unused'
  )

# total children ----
children_summed <- credentials_normalized %>%
  mutate(total_cumulative_enrolled_children = total_cumulative_enrollment - pregnant_women, .after = pregnant_women)

# service location (state col) ----

## join centers data to pir import
service_locations <- children_summed %>% 
  distinct(state, grant_number, program_number, program_type, year)

service_locations <- left_join(service_locations, service_location_check_table, by = c('grant_number', 'program_number', 'program_type'))

missing_grants_in_centers_data <- service_locations %>%
  filter(if_any(any_of(c('multi_state', 'states_abbr', 'states')), is.na)) %>%
  select(state, grant_number, program_number, program_type, year) 

print(paste0('There are ', nrow(distinct(missing_grants_in_centers_data, grant_number)), ' grants covering ', 
             nrow(missing_grants_in_centers_data), ' programs that cannot be found in the centers data.'))

## flag multi-state grants and incorrect service locations
incorrect_service_location <- left_join(
  children_summed,
  service_location_check_table,
  by = c('grant_number', 'program_number', 'program_type')
) %>%
  filter(multi_state | states_abbr != state) %>%
  mutate(count_states = str_count(states_abbr, ',') + 1) %>%
  select(year, region, state, states_abbr, multi_state, grant_number, program_number,program_type)

print(paste0('There are ', nrow(distinct(incorrect_service_location, grant_number)), ' grants covering ',
             nrow(incorrect_service_location), ' programs with service locations that need review.'))

## fix the service location for records that aren't multi-state
corrected_service_location <- left_join(
  children_summed,
  service_location_check_table,
  by = c('grant_number', 'program_number', 'program_type')
) %>% 
  mutate(state = ifelse(!multi_state & 
                          states_abbr != state & 
                          !is.na(states_abbr), states_abbr, state)) 

## append region for records that had their state value corrected
region_mismatch <- left_join(
  corrected_service_location,
  region_state_crosswalk,
  by = c('states_abbr' = 'Abbreviation')
) %>%
  filter(region != Region) %>%
  select(year, 'pir_region' = region, 'crosswalk_region' = Region, 'pir_state' = state, 'centers_state' = states_abbr, grant_number, program_number, program_type) %>%
  arrange(desc(pir_region)) 

# finalize names and columns ----
export_data <- corrected_service_location  %>%
  mutate(
    uid = paste(grant_number, program_number, year, sep = '-')
  ) %>%
  select(
    # id and geo cols 
    uid,
    year,
    region, 
    'service_state' = state,
    'grantee_name' = grantee,
    grant_number,
    grant_type,
    'program_name' = program,
    program_number,
    program_type,
    # enrollment and demographics
    total_cumulative_enrollment,
    total_cumulative_enrolled_children,
    'newly_enrolled_children' = number_of_all_newly_enrolled_children_since_last_year_s_pir_was_reported,
    less_than_1_year_old:pregnant_women,
    'hispanic_or_latino_origin_any_race_enrollees' = hispanic_or_latino_origin,
    'asian_non_hispanic_enrollees' = asian,
    'black_or_african_american_non_hispanic_enrollees' = black_or_african_american,
    'native_hawaiian_pacific_islander_non_hispanic_enrollees' = native_hawaiian_pacific_islander,
    'white_non_hispanic_enrollees' = white,
    'biracial_or_multi_racial_non_hispanic_enrollees' = biracial_or_multi_racial,
    'other_race_non_hispanic_enrollees' = other_race,
    # eligibility
    income_eligibility,
    'receipt_of_public_assistance_eligibility' = receipt_of_public_assistance,
    'foster_children_eligibility' = foster_children,
    'homeless_children_eligibility' = homeless_children,
    'over_income_eligibility' = over_income,
    'income_between_100_percent_and_130_percent_of_poverty_eligibility' = income_between_100_percent_and_130_percent_of_poverty,
    # staff
    'total_noncontracted_staff' = total_hs_staff,
    total_contracted_staff,
    total_departed_staff,
    'total_departed_noncontracted_staff' = total_departed_hs_staff,
    total_departed_contracted_staff,
    'total_hs_prek_teachers' = total_hs_teachers,
    'total_ehs_it_teachers' = total_ehs_teachers,
    total_departed_teachers,
    total_assistant_teachers,
    total_home_visitors,
    total_family_child_care_providers,
    # credentials
    'advanced_degree_hs_prek_teachers' = advanced_degree_classroom_teachers,
    'baccalaureate_degree_hs_prek_teachers' = baccalaureate_degree_classroom_teachers,
    'associate_degree_hs_prek_teachers' = associate_degree_classroom_teachers,
    cda_hs_prek_teachers,
    'no_credential_hs_prek_teachers' = unqualified_hs_teachers,
    'advanced_degree_ehs_it_teachers' = advanced_degree_infant_and_toddler_classroom_teachers,
    'baccalaureate_degree_ehs_it_teachers' = baccalaureate_degree_infant_and_toddler_classroom_teachers,
    'associate_degree_ehs_it_teachers' = associate_degree_infant_and_toddler_classroom_teachers,
    cda_ehs_it_teachers,
    'no_credential_ehs_it_teachers' = unqualified_ehs_teachers,
    # health and healthcare
    children_with_health_insurance_at_enrollment,
    children_with_health_insurance_at_end_of_enrollment_year,
    'children_with_ongoing_source_of_continuous_accessible_health_care_at_enrollment_start' = number_of_children_with_an_ongoing_source_of_continuous_accessible_health_care_provided_by_a_health_care_professional_that_maintains_their_ongoing_health_record_and_is_not_primarily_a_source_of_emergency_or_urgent_care_at_enrollment,
    'children_with_ongoing_source_of_continuous_accessible_health_care_at_end_enrollment' = number_of_children_with_an_ongoing_source_of_continuous_accessible_health_care_provided_by_a_health_care_professional_that_maintains_their_ongoing_health_record_and_is_not_primarily_a_source_of_emergency_or_urgent_care_at_end_enrollment,
    'children_up_to_date_on_epdst_at_enrollment_start' = children_up_to_date_according_to_relevant_states_epsdt_schedule_at_enrollment,
    'children_up_to_date_on_epdst_at_enrollment_end' = children_up_to_date_according_to_relevant_states_epsdt_schedule_at_end_of_enrollment_year,
    'hs_prek_children_with_an_iep' = children_with_an_iep,
    'ehs_it_children_with_an_iep' = children_with_an_ifsp,
    'hs_prek_health_impairment' = health_impairment,
    'hs_prek_emotional_disturbance' = emotional_disturbance,
    'hs_prek_speech_impairment' = speech_impairment,
    'hs_prek_intellectual_disabilities' = intellectual_disabilities,
    'hs_prek_hearing_impairment' = hearing_impairment,
    'hs_prek_orthopedic_impairment' = orthopedic_impairment,
    'hs_prek_visual_impairment' = visual_impairment,
    'hs_prek_specific_learning_disabilities' = specific_learning_disabilities,
    'hs_prek_autism' = autism,
    'hs_prek_traumatic_brain_injury' = traumatic_brain_injury,
    'hs_prek_non_categorical_developmental_delay' = non_categorical_developmental_delay,
    'hs_prek_multiple_disabilities_excluding_deaf_blind' = multiple_disabilities_excluding_deaf_blind,
    'hs_prek_deaf_blind' = deaf_blind,
    newly_enrolled_children_who_completed_behavorial_screenings,
    # homeless and foster children
    homeless_children_served,
    foster_care_children_served
  )

# export ----
path <- here::here('pir-metrics', 'clean', 'output', str_glue('pir_clean_{years[1]}_{years[length(years)]}.csv'))
write_csv(export_data, path, na = '')

path <- here::here('pir-metrics', 'clean', 'output', 'region_mismatch.csv')
write_csv(region_mismatch, path)

path <- here::here('pir-metrics', 'clean', 'output', 'incorrect_service_locations.csv')
write_csv(incorrect_service_location, path)

path <- here::here('pir-metrics', 'clean', 'output', 'missing_grants_in_centers_data.csv')
write_csv(missing_grants_in_centers_data, path)

rm(list = ls())
