-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This view provides a list of distinct linked questions and the year they first appeared.
-- =============================================
DROP VIEW IF EXISTS pir_question_links.distinct_linked_v;

CREATE OR REPLACE VIEW pir_question_links.distinct_linked_v AS
SELECT a.*, b.`year` AS first_appearance
FROM (
	SELECT DISTINCT question_id, question_name, question_text, question_number, category, section
    FROM linked
) a
LEFT JOIN new_questions b
ON a.question_id = b.question_id
;