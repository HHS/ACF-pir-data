-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This view provides a list of distinct linked questions and the year they first appeared.
-- =============================================
DROP VIEW IF EXISTS pir_question_links.distinct_linked_v;

CREATE OR REPLACE VIEW pir_question_links.distinct_linked_v AS
WITH 
distinct_linked AS (
SELECT DISTINCT question_id, question_name, question_text, question_number, category, section
FROM linked
)
SELECT distinct_linked.*, new_questions_v.`year` AS first_appearance
FROM distinct_linked
LEFT JOIN new_questions_v
ON distinct_linked.question_id = new_questions_v.question_id
;