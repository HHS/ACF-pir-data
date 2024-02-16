CREATE OR REPLACE VIEW inconsistent_question_id_v AS
SELECT DISTINCT a.uqid, 1 AS inconsistent_question_id
FROM linked a
INNER JOIN (
	SELECT DISTINCT uqid
	FROM (
		SELECT uqid, question_id, lag(question_id) over (PARTITION BY uqid) as lag_question_id
		FROM linked
	) b
	WHERE b.lag_question_id IS NOT NULL AND b.lag_question_id != question_id
) c
ON a.uqid = c.uqid
;