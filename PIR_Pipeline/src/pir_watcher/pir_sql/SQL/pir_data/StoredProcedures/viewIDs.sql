call makeAggregateViews();

SELECT DISTINCT question_id
FROM question_links.linked
WHERE uqid IN (
	SELECT a.uqid
	FROM question_links.linked a
	INNER JOIN (
		SELECT distinct question_id
		FROM question
		WHERE question_name REGEXP "cumulative"
	) b
    ON a.question_id = b.question_id
)
UNION
SELECT a.question_id
FROM question_links.unlinked a
INNER JOIN (
	SELECT distinct question_id
	FROM question
	WHERE question_name REGEXP "cumulative"
) b
ON a.question_id = b.question_id
;