library(janitor)
library(tidyverse)
library(readxl)
year <- c('2019', '2021', '2022')

# Read PIR data ----
read_pir_export <- function(year) {
  pir_path <- here::here('pir-metrics', 'import', 'input', str_glue('pir_export_{year}.xlsx'))
  
  # Prepare comprehensive PIR data frame ----
  pirA <- read_excel(pir_path,
                     sheet = 'Section A', skip = 1)
  pirB <- read_excel(pir_path,
                     sheet = 'Section B', skip = 1)
  pirC <- read_excel(pir_path,
                     sheet = 'Section C', skip = 1)
  
  pir <- list(pirA, pirB, pirC) %>%
    reduce(left_join)
  
  # Prepare PIR reference table for col identification ----
  pir_ref <- read_excel(pir_path,
                        sheet = 'Reference')
  
  pir_ref <- pir_ref %>%
    janitor::clean_names()
  
  pir_ref <- pir_ref %>%
    mutate(across(c(question_number, question_name), janitor::make_clean_names)) %>% 
    select(question_number, question_name) 
  
  list(
    'year' = year,
    'data' = pir,
    'reference' = pir_ref
  )
}

pir19 <- read_pir_export(year[1])
pir21 <- read_pir_export(year[2])
pir22 <- read_pir_export(year[3])

## Define extract col names ----
id_cols <- c('region', 'state', 'grant_number', 'program_number', 'type', 'grantee', 'program', 'city', 'zip_code', 'zip_4')

extract_cols <- c(
  # Cumulative Enrollment
  # 'total_cumulative_enrollment_of_children',
  'total_cumulative_enrollment', 
  'pregnant_women', # total_cumulative_enrollment - pregnant_women = total_cumulative_enrollment_of_children
  # Race / Ethnicity
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
  # Age
  # 'less_than_1_year_old',
  # 'x1_year_old',
  # 'x2_years_old',
  # 'x3_years_old',
  # 'x4_years_old',
  # 'x5_years_and_older',
  # Language spoken by children
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
  # Child Characteristics
  'homeless_children', 
  # 'foster_children', 
  # 'children_with_an_iep', 
  # 'children_with_an_ifsp',
  # Staff
  'total_head_start_staff', 
  'total_contracted_staff', 
  'total_staff', 
  'total_education_and_child_development_staff',
  # Staff Turnover
  #'total_departed_head_start_staff', # This is a 2019 specific variable
  'teacher_turnover_total', # This is a 2019 specific variable
  'home-based_visitor_turnover_total', # This is a 2019 specific variable, teacher_turnover_total + home-based_visitor_turnover_total = total_education_and_child_development_staff?
  'children_who_moved_out_education_and_child_development_staff', 
  # 'total_classroom_teachers', # total_preschool_teachers + total_infant_and_toddler_classroom_teachers = total_classroom teachers
  'total_preschool_teachers',
  'total_infant_and_toddler_classroom_teachers',
  # Staff education
  # 'associate_degree_classroom_teachers', 
  # 'advanced_degree_classroom_teachers', 
  # 'baccalaureate_degree_classroom_teachers', 
  # 'associate_degree_classroom_teachers', 
  # 'cda_classroom_teachers',
  # EPDST
  'children_up_to_date_according_to_relevant_states_epsdt_schedule_at_enrollment',
  'children_up_to_date_according_to_relevant_states_epsdt_schedule_at_end_of_enrollment_year',
  # Behavioral Screenings
  'newly_enrolled_children_who_completed_behavorial_screenings'
  # Health Insurance and Care
  # 'children_with_health_insurance_at_enrollment', 
  # 'children_with_health_insurance_at_end_of_enrollment_year', 
  # 'number_of_children_with_no_health_insurance_at_enrollment', 
  # 'number_of_children_with_no_health_insurance_at_end_of_enrollment',
  # 'number_of_children_with_an_ongoing_source_of_continuous_accessible_health_care_provided_by_a_health_care_professional_that_maintains_their_ongoing_health_record_and_is_not_primarily_a_source_of_emergency_or_urgent_care_at_enrollment'
)

## Pull reference tables ----
create_reference_objects <- function(data) {
  data %>% 
    filter(question_name %in% c(id_cols, extract_cols))
}

pir19_ref <- create_reference_objects(pir19[['reference']])
pir21_ref <- create_reference_objects(pir21[['reference']])
pir22_ref <- create_reference_objects(pir22[['reference']])

# Extract final PIR data frame ----
finalize_export <- function(data, ref) {
  ref_renamer <- deframe(ref)
  
  data %>%
    janitor::clean_names() %>%
    select(all_of(c(id_cols, ref$question_number))) %>%
    rename_with(
      .fn = \(x) ref_renamer[x],
      .cols = -all_of(id_cols)
    )
}

pir19_export <- finalize_export(pir19[['data']], pir19_ref)
pir21_export <- finalize_export(pir21[['data']], pir21_ref)
pir22_export <- finalize_export(pir22[['data']], pir22_ref)


# Export ----
export_pir <- function(pir_export, year) {
  if (nrow(pir) != nrow(pir_export)) warning('Exported file is missing rows.')
  export_path <- here::here('pir-metrics', 'import', 'output', str_glue('pir_{year}.csv'))
  write_csv(pir_export, export_path)
}

export_pir(pir19_export, year[1])
export_pir(pir21_export, year[2])
export_pir(pir22_export, year[3])

rm(list = ls()) # TODO: Remove this

# 2022: B.3-1, B.3-2, B.6, B.8, and B.9 = total number of HS education staff; B.15 / this is % spanish proficient non-supervisory education and child development staff

# Check for missing values across years ---
# year <- '2019'
# if (file.exists(here::here('pir-metrics', 'import', 'output', str_glue('pir_{year}.csv')))) {
#   pir_2019 <- read_csv(here::here('pir-metrics', 'import', 'output', str_glue('pir_{year}.csv')))
#   check_2019 <- tibble(
#     qnames = names(pir_2019),
#     dummy = year
#   )
#   df <- left_join(
#     pir_ref_select,
#     check_2019,
#     by = c('question_name' = 'qnames')
#   )
#   df %>%
#     filter(is.na(dummy)) %>%
#     pull(question_name)
# }

shared_names <- read_csv(here::here('pir-metrics', 'import', 'output', 'shared_names.csv'))
shared_names %>%
  filter(if_any(everything(), is.na))
