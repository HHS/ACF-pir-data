-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: Generate a new column based on a linear combination of two others.
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
		'WITH
        question_1 AS (
			SELECT uid, answer, `year`
			FROM pir_data.response
            WHERE question_id = ', QUOTE(qid1),
		'),
        question_2 AS (
			SELECT uid, COALESCE(answer, 0) as answer, `year`
			FROM pir_data.response
			WHERE question_id = ', QUOTE(qid2),
		')
		SELECT question_1.uid, question_1.`year`, question_1.answer AS ', name1, 
			', question_2.answer AS ', name2, ', question_1.answer ', operation,' question_2.answer AS ', construct_name, ' 
		FROM question_1
		INNER JOIN question_2
		ON question_1.uid = question_2.uid AND question_1.`year` = question_2.`year`
		ORDER BY question_1.uid, question_1.`year`'
    );
    
    -- Prepare and execute the query
    PREPARE statement FROM @construct_query;
    EXECUTE statement;
    DEALLOCATE PREPARE statement;

END //
DELIMITER ;