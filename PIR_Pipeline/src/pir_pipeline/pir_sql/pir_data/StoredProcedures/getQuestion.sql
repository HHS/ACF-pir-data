-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This stored procedure queries the response table to get question-level data based on a question ID and kind of ID (uqid or question ID).
-- Parameters:
--  IN qid VARCHAR(255) - The question ID or unique question ID (uqid) to filter on.
--  IN kind VARCHAR(12) - The kind of ID to filter on (uqid or question ID). If uqid, the procedure will return all responses for the questions linked to the uqid. 
-- If question ID, the procedure will return all responses for the specified question ID.
-- Returns: None
-- Examples: 
--	CALL pir_data.getQuestion('4fbac59c868a7255a0acb42bd6e2ec54', 'question_id');
--	CALL pir_data.getQuestion('0addede781364f83866353b43a90fe34', 'uqid');
-- 	CALL pir_data.getQuestion('00e4f2d1-adaf-4f1c-8bf2-3ffb8445d960', 'uqid');
-- =============================================

DROP PROCEDURE IF EXISTS pir_data.getQuestion;

DELIMITER //

CREATE PROCEDURE pir_data.getQuestion(
	IN qid VARCHAR(255),
    IN kind VARCHAR(12)
)
BEGIN
	
    IF kind = 'uqid' THEN
		-- If passed a uqid, get all responses for the questions linked to the uqid
		IF INSTR(qid, "-") > 0 THEN
        
			SET @question_query = CONCAT(
				'SELECT a.* ',
                'FROM response a ',
                'INNER JOIN (
					SELECT DISTINCT question_id
                    FROM pir_question_links.linked b
                    WHERE uqid = ', QUOTE(qid), ' '
                ') b
                ON a.question_id = b.question_id
                '
            );
        -- If passed a question ID, identify the uqid associated with that question ID and get all responses for the questions linked to the uqid
        ELSE

			SET @question_query = CONCAT(
				'SELECT a.* ',
				'FROM response a ',
				'INNER JOIN (
					SELECT DISTINCT question_id
					FROM pir_question_links.linked b
					INNER JOIN (
						SELECT DISTINCT uqid 
						FROM pir_question_links.linked 
						WHERE question_id = "', qid, '" ',
					') c
					ON b.uqid = c.uqid
				) d
				ON a.question_id = d.question_id
				'
			);
        
        END IF;
    -- If passed a question ID, get all responses for the specified question ID
	ELSE
		
        SET @question_query = CONCAT(
			'SELECT * ',
            'FROM response ',
            'WHERE question_id = "', qid, '"'
        );
        
	END IF;

	-- Prepare and execute the query    
    SELECT @question_query;
    
    PREPARE statement FROM @question_query;
    EXECUTE statement;
    DEALLOCATE PREPARE statement;

END //

DELIMITER ;