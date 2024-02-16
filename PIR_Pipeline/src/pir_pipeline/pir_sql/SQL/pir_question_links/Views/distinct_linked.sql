DROP VIEW IF EXISTS distinct_linked_v;

CREATE OR REPLACE VIEW distinct_linked_v AS
SELECT a.*, b.`year` AS first_appearance
FROM (
	SELECT DISTINCT question_id, question_name, question_text, question_number, category, section
    FROM linked
) a
LEFT JOIN new_questions b
ON a.question_id = b.question_id
;