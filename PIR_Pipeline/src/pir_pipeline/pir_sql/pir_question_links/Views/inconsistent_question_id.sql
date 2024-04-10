-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This view provides a list of questions that have inconsistent question IDs.
-- =============================================

CREATE OR REPLACE VIEW pir_question_links.inconsistent_question_id_v AS
WITH
lag_qid AS (
	SELECT uqid, question_id, lag(question_id) over (PARTITION BY uqid) as lag_question_id
	FROM pir_question_links.linked
),
inconsistent AS (
	SELECT DISTINCT uqid
	FROM lag_qid
	WHERE lag_question_id IS NOT NULL AND lag_question_id != question_id
)
SELECT DISTINCT pir_question_links.linked.uqid, 1 AS inconsistent_question_id
FROM pir_question_links.linked
INNER JOIN inconsistent
ON pir_question_links.linked.uqid = inconsistent.uqid
;