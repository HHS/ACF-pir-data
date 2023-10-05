library(janitor)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(readr)
library(tibble)
library(readxl)
years <- c('2019', '2021', '2022')

# Read PIR data ----
read_pir_export <- function(year) {
  pir_path <- here::here('pir-metrics', 'import', 'input', str_glue('pir_export_{year}.xlsx'))
  
  ## Prepare PIR report data frame ----
  pirA <- read_excel(pir_path,
                     sheet = 'Section A', skip = 1)
  pirB <- read_excel(pir_path,
                     sheet = 'Section B', skip = 1)
  pirC <- read_excel(pir_path,
                     sheet = 'Section C', skip = 1)
  
  pir <- list(pirA, pirB, pirC) %>%
    reduce(left_join, by = c('Region', 'State', 'Grant Number', 'Program Number', 'Type', 'Grantee', 'Program', 'City', 'ZIP Code', 'ZIP 4'))
  
  # some pir exports include a totals row that is unnecessary
  pir <- pir %>%
    filter(Region != 'Totals')
  
  ## Prepare PIR reference table for col identification ----
  pir_ref <- read_excel(pir_path,
                        sheet = 'Reference')
  
  pir_ref <- pir_ref %>%
    janitor::clean_names()
  
  pir_ref <- pir_ref %>%
    mutate(across(c(question_number, question_name), janitor::make_clean_names)) %>% 
    select(question_number, question_name) 
  
  ## Prepare program details table ----
  pir_programs <- read_excel(pir_path,
                             sheet = 'Program Details')
  
  pir_programs <- pir_programs %>%
    janitor::clean_names()
  
  ## Output list object of read data ----
  list(
    'year' = year,
    'data' = pir,
    'reference' = pir_ref,
    'programs' = pir_programs
  )
}

pir19 <- suppressWarnings(read_pir_export(years[1]))
pir21 <- suppressWarnings(read_pir_export(years[2]))
pir22 <- suppressWarnings(read_pir_export(years[3]))

## Define extract col names ----
id_cols <- c('region', 'state', 'grant_number', 'grant_type', 'program_number', 'type', 'grantee', 'program', 'city', 'zip_code', 'zip_4')
program_cols <- c('region', 'grant_number', 'program_number', 'program_type', 'grantee_name', 'program_name')

extract_cols <- c(
  ## Cumulative Enrollment
  ## 'total_cumulative_enrollment_of_children',
  'total_cumulative_enrollment', 
  'pregnant_women', # total_cumulative_enrollment - pregnant_women = total_cumulative_enrollment_of_children
  ## Race / Ethnicity
  'american_indian_alaska_native_hispanic_or_latino_origin',
  'american_indian_alaska_native_non_hispanic_or_non_latino_origin',
  'asian_hispanic_or_latino_origin',
  'asian_non_hispanic_or_non_latino_origin',
  'black_or_african_american_hispanic_or_latino_origin',
  'black_or_african_american_non_hispanic_or_non_latino_origin',
  'native_hawaiian_pacific_islander_hispanic_or_latino_origin',
  'native_hawaiian_pacific_islander_non_hispanic_or_non_latino_origin',
  'white_hispanic_or_latino_origin',
  'white_non_hispanic_or_non_latino_origin',
  'biracial_or_multi_racial_hispanic_or_latino_origin',
  'biracial_or_multi_racial_non_hispanic_or_non_latino_origin',
  'other_race_hispanic_or_latino_origin',
  'other_race_non_hispanic_or_non_latino_origin',
  ## Age
  'less_than_1_year_old',
  'x1_year_old',
  'x2_years_old',
  'x3_years_old',
  'x4_years_old',
  'x5_years_and_older',
  ## Language spoken by children
  # 'total_of_dual_language_learners',
  # 'english',
  # 'of_these_the_of_children_acquiring_learning_another_Language_in_addition_to_english',
  # 'spanish',
  # 'central_south_american_and_mexican',
  # 'caribbean_languages',
  # 'middle_eastern_south_asian_languages',
  # 'east_asian_languages',
  # 'native_north_american_alaska_native_languages',
  # 'pacific_island_languages',
  # 'european_and_slavic_languages',
  # 'african_languages',
  # 'american_sign_language', # Is contained within the "Other" text response category prior to 2021
  # 'other_languages',
  # 'unspecified_languages',
  ## Child Characteristics
  'homeless_children', 
  # 'foster_children', 
  'children_with_an_iep',
  'children_with_an_ifsp',
  ## Children with disabilities
  'health_impairment', 
  'emotional_disturbance',
  'speech_impairment',
  'intellectual_disabilities', 
  'hearing_impairment',
  'orthopedic_impairment',
  'visual_impairment',
  'specific_learning_disabilities',
  'autism',
  'traumatic_brain_injury',
  'non_categorical_developmental_delay',
  'multiple_disabilities_excluding_deaf_blind',
  'deaf_blind',
  ## Staff
  'total_head_start_staff', # 2019/21/22 total staff
  'total_contracted_staff', # 2019/21/22 total staff
  'total_classroom_teachers', # 2022/21 HS teachers
  'total_infant_and_toddler_classroom_teachers', #2019/21/22 EHS teachers
  'total_preschool_classroom_teachers', # 2019 HS teachers
  'number_of_all_newly_enrolled_children_since_last_year_s_pir_was_reported',
  ## Staff Turnover
  'teacher_turnover_total', # 2019 departed teachers
  'total_departed_head_start_staff', # 2019 departed staff
  'total_departed_contracted_staff', # 2019 departed staff
  'total_contracted_staff_2', # 2022/21 departed staff
  'total_staff', # 2022/21 departed staff
  'children_who_moved_out_education_and_child_development_staff', # 2022 departed teachers, note that this doesn't exist for '21
  ## Staff education
  # 'associate_degree_classroom_teachers', 
  # 'advanced_degree_classroom_teachers', 
  # 'baccalaureate_degree_classroom_teachers', 
  # 'associate_degree_classroom_teachers', 
  # 'cda_classroom_teachers',
  ## EPDST
  'children_up_to_date_according_to_relevant_states_epsdt_schedule_at_enrollment',
  'children_up_to_date_according_to_relevant_states_epsdt_schedule_at_end_of_enrollment_year',
  ## Behavioral Screenings
  'newly_enrolled_children_who_completed_behavorial_screenings',
  ## Health Insurance and Care
  'children_with_health_insurance_at_enrollment',
  'children_with_health_insurance_at_end_of_enrollment_year',
  'children_continuous_accessible_health_care_at_enrollment',
  'children_continuous_accessible_health_care_at_end_of_enrollment_year',
  'number_of_children_with_no_health_insurance_at_enrollment',
  'number_of_children_with_no_health_insurance_at_end_of_enrollment',
  'number_of_children_with_an_ongoing_source_of_continuous_accessible_health_care_provided_by_a_health_care_professional_that_maintains_their_ongoing_health_record_and_is_not_primarily_a_source_of_emergency_or_urgent_care_at_enrollment',
  'number_of_children_with_an_ongoing_source_of_continuous_accessible_health_care_provided_by_a_health_care_professional_that_maintains_their_ongoing_health_record_and_is_not_primarily_a_source_of_emergency_or_urgent_care_at_end_enrollment'
)

## Pull reference tables ----
create_reference_table <- function(pir_data) {
  pir_data[['reference']] %>% 
    filter(question_name %in% c(id_cols, extract_cols))
}

pir19_ref <- create_reference_table(pir19)
pir21_ref <- create_reference_table(pir21)
pir22_ref <- create_reference_table(pir22)

## Identify question name differences across reference tables ----
ref_list <- list('2019' = pir19_ref, '2021' = pir21_ref, '2022' = pir22_ref)

ref_diff_table <- map(
  years, 
  \(x) {
    ref_list[[x]] %>%
      mutate(year = x) 
  }
) %>%
  reduce(bind_rows) %>%
  pivot_wider(
    names_from  = year,
    names_glue = 'year_{year}',
    values_from = question_number
  )

### crosswalk for normalizing variables before export, based on ref diff table ----
extract_var_crosswalk <- c(
  ## Child healthcare
  'children_continuous_accessible_health_care_at_enrollment' =  'number_of_children_with_an_ongoing_source_of_continuous_accessible_health_care_provided_by_a_health_care_professional_that_maintains_their_ongoing_health_record_and_is_not_primarily_a_source_of_emergency_or_urgent_care_at_enrollment', # 2022 continuous access to care
  'children_continuous_accessible_health_care_at_end_of_enrollment_year' = 'number_of_children_with_an_ongoing_source_of_continuous_accessible_health_care_provided_by_a_health_care_professional_that_maintains_their_ongoing_health_record_and_is_not_primarily_a_source_of_emergency_or_urgent_care_at_end_enrollment', # 2022 continuous access to care
  ## Staff
  'total_head_start_staff' = 'total_hs_staff', # 2019/21/22 total staff
  'total_contracted_staff' = 'total_contracted_staff', # 2019/21/22 total staff
  'total_classroom_teachers' = 'total_hs_teachers', # 2022/21 HS teachers
  'total_infant_and_toddler_classroom_teachers' = 'total_ehs_teachers', #2019/21/22 EHS teachers
  'total_preschool_classroom_teachers' = 'total_hs_teachers', # 2019 HS teachers
  ## Staff Turnover
  'teacher_turnover_total' = 'total_departed_teachers', # 2019 departed teachers
  'total_departed_head_start_staff' = 'total_departed_hs_staff', # 2019 departed staff
  'total_departed_contracted_staff' = 'total_departed_contracted_staff', # 2019 departed staff
  'total_contracted_staff_2' = 'total_departed_contracted_staff', # 2022/21 departed staff
  'total_staff' = 'total_departed_staff', # 2022/21 departed staff
  'children_who_moved_out_education_and_child_development_staff' = 'total_departed_teachers' # 2022 departed teachers, note that this doesn't exist for '21
)

ref_diff_table <- ref_diff_table %>%
  mutate(question_name_normalized = ifelse(is.na(extract_var_crosswalk[question_name]), 
                                           question_name, 
                                           extract_var_crosswalk[question_name]))

write_csv(ref_diff_table,
          here::here('pir-metrics', 'import', 'output', 'ref_diff_table.csv'))

# Extract final PIR data frame ----
finalize_export <- function(pir_data, year) {
  ref_renamer <- ref_diff_table %>%
    select(sym(paste0('year_', year)), question_name_normalized) %>%
    drop_na %>%
    deframe
  
  df <- pir_data[['data']] %>%
    janitor::clean_names() %>%
    select(any_of(c(id_cols, names(ref_renamer)))) %>%
    mutate(grant_type = str_extract(grant_number, '[A-Z]{2}'), .after = 'grant_number') %>%
    rename_with(
      .fn = \(x) ref_renamer[x],
      .cols = -all_of(id_cols)
    ) 
  
  df %>%
    left_join(pir_data[['programs']], 
              by = c('region', 'grant_number', 'program_number', 'type' = 'program_type', 'grantee' = 'grantee_name', 'program' = 'program_name')) %>%
    select(all_of(id_cols), starts_with('program'), everything()) %>%
    rename('program_type' = 'type')
}

pir19_export <- finalize_export(pir19, years[1])
pir21_export <- finalize_export(pir21, years[2])
pir22_export <- finalize_export(pir22, years[3])

## Manually add in missing column from 2021 (children_who_moved_out_education_and_child_development_staff | total_departed_teachers) ----
pir21_export$total_departed_teachers <- NA_real_

## Stop and throw an error if exports don't all have matched col names and types ----
if (!janitor::compare_df_cols_same(pir19_export, pir21_export, pir22_export)) {
  warning('Export columns are not normalized. Col names or types do not match.')
}

# Export ----
export_pir <- function(pir_export, year) {
  export_path <- here::here('pir-metrics', 'import', 'output', str_glue('pir_{year}.csv'))
  write_csv(pir_export, export_path)
}

export_pir(pir19_export, years[1])
export_pir(pir21_export, years[2])
export_pir(pir22_export, years[3])

## Single file ----
pir_longitudinal <- list(
  pir19_export %>%
    mutate(year = '2019', .after = grant_number),
  pir21_export %>%
    mutate(year = '2021', .after = grant_number),
  pir22_export %>%
    mutate(year = '2022', .after = grant_number)
) %>%
  reduce(bind_rows)

path <- here::here('pir-metrics', 'import', 'output', str_glue('pir_{years[1]}_{years[length(years)]}.csv'))
write_csv(pir_longitudinal, path)

rm(list = ls())
