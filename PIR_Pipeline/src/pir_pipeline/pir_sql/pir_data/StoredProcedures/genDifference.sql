-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This stored procedure generates a difference between two questions and stores the result in a new column.
-- Parameters:
--   IN operation CHAR(1) - The operation to perform (+, -, *, /)
--   IN qid1 TEXT - The ID of the first question
--   IN name1 VARCHAR(64) - The name of the first question column
--   IN qid2 TEXT - The ID of the second question
--   IN name2 VARCHAR(64) - The name of the second question column
--   IN construct_name VARCHAR(64) - The name of the new column to store the difference
-- Returns: None
-- Example: CALL pir_data.genDifference('-', '4fbac59c868a7255a0acb42bd6e2ec54', 'TotalCumulativeEnrollment', '0addede781364f83866353b43a90fe34', 'PregnantWomen', 'ChildEnrollment');
-- =============================================
DROP PROCEDURE IF EXISTS pir_data.genDifference;

DELIMITER //

CREATE PROCEDURE pir_data.genDifference(
	IN operation CHAR(1), 
	IN qid1 TEXT, 
	IN name1 VARCHAR(64), 
	IN qid2 TEXT, 
	IN name2 VARCHAR(64), 
	IN construct_name VARCHAR(64)
)
BEGIN

	-- Create the query to generate new constructed column
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
    
    -- Prepare and execute the query
    PREPARE statement FROM @construct_query;
    EXECUTE statement;
    DEALLOCATE PREPARE statement;

END //
DELIMITER ;