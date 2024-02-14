SELECT a.uid, a.`year`, a.answer AS TotalCumulEnr, b.answer as PregWmnCumulEnr, a.answer - b.answer as ChildCumulEnr
FROM (
	SELECT uid, answer, `year`
	FROM pir_data_test.response
	WHERE question_id = '4fbac59c868a7255a0acb42bd6e2ec54'
) a
INNER JOIN (
	SELECT uid, COALESCE(answer, 0) as answer, `year`
	FROM pir_data_test.response
	WHERE question_id = '7a3fba3c01b9d1d6a4d65be2b33d2ae6'
) b
ON a.uid = b.uid AND a.`year` = b.`year`
ORDER BY a.uid, a.`year`
;