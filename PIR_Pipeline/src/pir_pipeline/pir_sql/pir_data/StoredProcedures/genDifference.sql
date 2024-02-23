DROP PROCEDURE IF EXISTS pir_data.genDifference;

DELIMITER //

CREATE PROCEDURE pir_data.genDifference(
	IN operation CHAR(1), IN qid1 TEXT, IN name1 VARCHAR(64), IN qid2 TEXT, IN name2 VARCHAR(64), IN construct_name VARCHAR(64)
)
BEGIN

	SET @construct_query = CONCAT(
		'SELECT a.uid, a.`year`, a.answer AS ', name1, ', b.answer AS ', name2, ', a.answer ', operation,' b.answer AS ', construct_name, ' ',
		'FROM (
			SELECT uid, answer, `year`
			FROM pir_data.response
		',
		'	WHERE question_id = ', QUOTE(qid1),
		') a
		INNER JOIN (
			SELECT uid, COALESCE(answer, 0) as answer, `year`
			FROM pir_data.response
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