# Data Dictionary

uid
: A combination of the grant_number, program_number, and year values. Serves as a unique identifier for each row.

year
: The enrollment year of the PIR data collection.

region
: The Administration for Children and Families region of the grant recipient.

service_state
: The state or territory (abbreviated) the program was reported being located in. Note that some programs reported a different state than where their services were located. In these cases the state was updated to reflect the location of where services were located based on historical facility datasets.

grantee_name
: The name of the grant recipient organization.

grant_number
: The grant number associated with the program record. 

grant_type
: Pulled from the grant number, a two character code identifying the type of grant.

program_name
: The name of the program.

program_number
: A program identifier that distinguishes lead grant recipient agencies from delegate agencies. A value of 0 or 200 represents a lead agency. Any other value such as 1, 2, 201, or 202 represents a delegate agency. 

program_type
: The type of program. 

## PIR Reporting Values

total_cumulative_enrollment
: The cumulative number of enrollees for the program throughout the enrollment year. This is often higher than funded enrollment since it is a cumulative count of all enrollees including those that leave the program throughout the year. 

total_cumulative_enrolled_children
: The total number of children enrollees for the program throughout the enrollment year. This is often higher than funded enrollment since it is a cumulative count of all children enrollees including those that leave the program throughout the year. 

newly_enrolled_children
: The number of children that are newly enrolled into the program, and are not returning from the prior year.

less_than_1_year_old
: The number of children enrolled in the program who are less than 1 year old as of the date used by the local school systems used for determining age eligiblity for public school.

x1_year_old
: The number of children enrolled in the program who are 1 year old as of the date used by the local school systems used for determining age eligiblity for public school.

x2_years_old
: The number of children enrolled in the program who are 2 years old as of the date used by the local school systems used for determining age eligiblity for public school.

x3_years_old
: The number of children enrolled in the program who are 3 years old as of the date used by the local school systems used for determining age eligiblity for public school.

x4_years_old
: The number of children enrolled in the program who are 4 years old as of the date used by the local school systems used for determining age eligiblity for public school.

x5_years_and_older
: The number of children enrolled in the program who are 5 years old or older as of the date used by the local school systems used for determining age eligiblity for public school.

pregnant_women
: The number of pregnant people enrolled in the program.

income_eligibility
: The number of enrollees who were determined eligible due to a family income at or below 100% of the federal poverty line.

receipt_of_public_assistance_eligibility
: The number of enrollees who were determined eligible due to their receipt of public assistance, specifically TANF, SSI, or SNAP.

foster_children_eligibility
: The number of enrolled children who were determined eligible due to their status as foster children.

homeless_children_eligibility
: The number of enrollees who were determined eligible due to their status of experiencing homelessness.

over_income_eligibility
: The number of enrollees who were determined eligible based a type of need other than income, public assistance, foster care, or homelessness. This is commonly known as the over income category.

income_between_100_percent_and_130_percent_of_poverty_eligibility
: The number of enrollees who were determined eligible based on a family income between 100% and 130% of the federal poverty level.

hispanic_or_latino_origin_any_race_enrollees
: The count of program enrollees who identified as hispanic or latino, regardless of race.

asian_non_hispanic_enrollees
: The count of program enrollees who identified as asian, and did not identify as hispanic or latino.

black_or_african_american_non_hispanic_enrollees
: The count of program enrollees who identified as black or african-american, and did not identify as hispanic or latino.

native_hawaiian_pacific_islander_non_hispanic_enrollees
: The count of program enrollees who identified as native hawaiian or pacific islander, and did not identify as hispanic or latino.

white_non_hispanic_enrollees
: The count of program enrollees who identified as white, and did not identify as hispanic or latino.

biracial_or_multi_racial_non_hispanic_enrollees
: The count of program enrollees who identified as multi- or bi-racial, and did not identify as hispanic or latino.

other_race_non_hispanic_enrollees
: The count of program enrollees who identified as a race/ethnicity that wasn't covered by the other categories, and did not identify as hispanic or latino.

total_noncontracted_staff
: The total number of noncontracted Head Start staff at the program, regardless of the funding source for their salary or number of hours worked.

total_contracted_staff
: The total number of contracted Head Start staff at the program, regardless of the funding source for their salary or number of hours worked.

total_departed_staff
: The total number of staff at the program who had departed since the last PIR was reported.

total_departed_noncontracted_staff
: The total number of noncontracted staff at the program who had departed since the last PIR was reported.

total_departed_contracted_staff
: The total number of contracted staff at the program who had departed since the last PIR was reported.

total_hs_prek_teachers
: The total number of Head Start preschool classroom teachers at the program (teaching children ages 3 and up).

total_ehs_it_teachers
: The total number of Early Head Start infant and toddler classroom teachers at the program (teaching children under the age of 3).

total_departed_teachers
: The total number of teachers at the program who had departed since the last PIR was reported.

children_with_health_insurance_at_enrollment
: The number of children enrollees reported as having health insurance at the start of the enrollment year.

children_with_health_insurance_at_end_of_enrollment_year
: The number of children enrollees reported as having health insurance at the end of the enrollment year.

children_with_ongoing_source_of_continuous_accessible_health_care_at_enrollment_start
: The number of children enrollees reported as having an ongoing source of continuous accessible health care at the start of the enrollment year.

children_with_health_insurance_at_end_of_enrollment_year
: The number of children enrollees reported as having an ongoing source of continuous accessible health care at the end of the enrollment year.

children_up_to_date_on_epdst_at_enrollment_start
: The number of children up to date on a schedule of age-appropriate preventive and primary health care according to the relevant state's EPSDT schedule for well child care at the start of the enrollment year.

children_up_to_date_on_epdst_at_enrollment_end
: The number of children up to date on a schedule of age-appropriate preventive and primary health care according to the relevant state's EPSDT schedule for well child care at the end of the enrollment year. 

hs_prek_children_with_an_iep
: The number of Head Start preschool children (ages 3 and up) enrolled in the program who have an Individualized Education Program (IEP), at any time during the enrollment year, indicating they have been determined eligible by the LEA to receive special education and related services under the IDEA.

ehs_it_children_with_an_iep
: The number of infants and toddlers (under age 3) enrolled in the program with an IFSP, at any time during the enrollment year, indicating they have been determined eligible by the Part C Agency to receive special education and related services under the IDEA.

hs_prek_health_impairment
: The number of enrolled Head Start preschool children (ages 3 and up) determined to have a health impairment.

hs_prek_emotional_disturbance
: The number of enrolled Head Start preschool children (ages 3 and up) determined to have an emotional disturbance.

hs_prek_speech_impairment
: The number of enrolled Head Start preschool children (ages 3 and up) determined to have a speech impairment.

hs_prek_intellectual_disabilities
: The number of enrolled Head Start preschool children (ages 3 and up) determined to have intellectual disabilities.

hs_prek_hearing_impairment
: The number of enrolled Head Start preschool children (ages 3 and up) determined to have a hearing impairment.

hs_prek_orthopedic_impairment
: The number of enrolled Head Start preschool children (ages 3 and up) determined to have an orthopedic impairment.

hs_prek_visual_impairment
: The number of enrolled Head Start preschool children (ages 3 and up) determined to have a visual impairment.

hs_prek_specific_learning_disabilities
: The number of enrolled Head Start preschool children (ages 3 and up) determined to have a learning disability.

hs_prek_autism
: The number of enrolled Head Start preschool children (ages 3 and up) determined to have autism. 

hs_prek_traumatic_brain_injury
: The number of enrolled Head Start preschool children (ages 3 and up) determined to have a traumatic brain injury.

hs_prek_non_categorical_developmental_delay
: The number of enrolled Head Start preschool children (ages 3 and up) determined to have a non-categorical developmental delay.

hs_prek_multiple_disabilities_excluding_deaf_blind
: The number of enrolled Head Start preschool children (ages 3 and up) determined to have multiple disabilities excluding deaf-blind.

hs_prek_deaf_blind
: The number of enrolled Head Start preschool children (ages 3 and up) determined to be deaf-blind.

newly_enrolled_children_who_completed_behavorial_screenings
: The number of newly enrolled children who completed behavioral screenings within 45 days for developmental, sensory, and behavioral concerns.

homeless_children_served
: Total number of children experiencing homelessness that were served during the enrollment year.

foster_care_children_served
: Total number of enrolled children who were in foster care at any point during the program year.

advanced_degree_hs_prek_teachers 
: The total number of Head Start preschool classroom teachers with an advanced degree. 

baccalaureate_degree_hs_prek_teachers 
: The total number of Head Start preschool classroom teachers with a baccalaureate degree.

associate_degree_hs_prek_teachers 
: The total number of Head Start preschool classroom teachers with an associate degree.

cda_hs_prek_teachers
: The total number of Head Start preschool classroom teachers with a Child Development Associate (CDA) credential.

no_credential_hs_prek_teachers
: The total number of Head Start preschool classroom teachers with no credentials.

advanced_degree_ehs_it_teachers
: The total number of Early Head Start infant and toddler classroom teachers with an advanced degree.

baccalaureate_degree_ehs_it_teachers
: The total number of Early Head Start infant and toddler classroom teachers with a baccalaureate degree.

associate_degree_ehs_it_teachers
: The total number of Early Head Start infant and toddler classroom teachers with an associate degree.

cda_ehs_it_teachers
: The total number of Early Head Start infant and toddler classroom teachers with a Child Development Associate (CDA) credential.

no_credential_ehs_it_teachers
: The total number of Early Head Start infant and toddler classroom teachers with no credentials.
