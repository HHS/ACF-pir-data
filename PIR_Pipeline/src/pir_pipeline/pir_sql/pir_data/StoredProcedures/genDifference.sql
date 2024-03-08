
DROP PROCEDURE IF EXISTS pir_data.genDifference;

-- The DELIMITER statement changes the default delimiter from ';' to '//' for the subsequent CREATE PROCEDURE statement.

DELIMITER //

-- This CREATE PROCEDURE statement defines the genDifference stored procedure.
CREATE PROCEDURE pir_data.genDifference(
	IN operation CHAR(1), -- Input parameter to specify the operation (+, -, *, /) for computing the difference.
	IN qid1 TEXT, -- Input parameter representing the first question ID.
	IN name1 VARCHAR(64), -- Input parameter representing the name for the first question.
	IN qid2 TEXT, -- Input parameter representing the second question ID.
	IN name2 VARCHAR(64), -- Input parameter representing the name for the second question.
	IN construct_name VARCHAR(64) -- Input parameter representing the name for the constructed difference.
)
BEGIN
    -- Concatenating the SQL query using the CONCAT function and storing it in a variable @construct_query.
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
    
    -- Uncommenting the following line would display the constructed SQL query for debugging purposes.
    -- SELECT @construct_query;
    
    -- Preparing and executing the dynamic SQL statement stored in @construct_query.
    PREPARE statement FROM @construct_query;
    EXECUTE statement;
    
    -- Deallocating the prepared statement to release resources.
    DEALLOCATE PREPARE statement;

END //

-- Resetting the delimiter back to ';' for subsequent SQL statements.
DELIMITER ;
