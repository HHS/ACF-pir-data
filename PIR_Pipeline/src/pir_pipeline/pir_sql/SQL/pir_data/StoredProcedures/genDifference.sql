DROP PROCEDURE IF EXISTS pir_data_test.genDifference;

DELIMITER //

CREATE PROCEDURE pir_data_test.genDifference(
	IN operation CHAR(1), IN qid1 TEXT, IN name1 VARCHAR(64), IN qid2 TEXT, IN name2 VARCHAR(64), IN construct_name VARCHAR(64)
)
BEGIN

	SET @construct_query = CONCAT(
		'SELECT a.uid, a.`year`, a.answer AS ', name1, ', b.answer AS ', name2, ', a.answer ', operation,' b.answer AS ', construct_name, ' ',
		'FROM (
			SELECT uid, answer, `year`
			FROM pir_data_test.response
		',
		'	WHERE question_id = ', QUOTE(qid1),
		') a
		INNER JOIN (
			SELECT uid, COALESCE(answer, 0) as answer, `year`
			FROM pir_data_test.response
		',
		'	WHERE question_id = ', QUOTE(qid2),
		') b
		ON a.uid = b.uid AND a.`year` = b.`year`
		ORDER BY a.uid, a.`year`'
    );
    
    -- SELECT @construct_query;
    PREPARE statement FROM @construct_query;
    EXECUTE statement;
    DEALLOCATE PREPARE statement;

END //
DELIMITER ;

call pir_data_test.genDifference("-", '4fbac59c868a7255a0acb42bd6e2ec54', 'TotalCumulEnr', '7a3fba3c01b9d1d6a4d65be2b33d2ae6', 'PregWmnCumulEnr', 'ChildCumulEnr');