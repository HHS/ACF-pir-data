-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 04/09/2024
-- Description: This view lists the first occurrence of each question
-- =============================================
CREATE OR REPLACE VIEW new_questions_v AS
WITH RECURSIVE
qid_year AS (
	SELECT DISTINCT `year`, question_id, question_number, question_name, question_text, category, section
	FROM linked
	UNION 
	SELECT DISTINCT `year`, question_id, question_number, question_name, question_text, category, section
	FROM unlinked
),
qid_first AS (
	SELECT question_id, min(`year`) as `year`
    FROM qid_year
    GROUP BY question_id
)
SELECT qid_year.* 
FROM qid_year
INNER JOIN qid_first
ON qid_year.question_id = qid_first.question_id AND qid_year.`year` = qid_first.`year`;
