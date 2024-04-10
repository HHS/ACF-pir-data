-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: Get program-level data from the response table by question ID.
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
				'WITH
                distinct_qid AS (
					SELECT DISTINCT question_id
                    FROM pir_question_links.linked b
                    WHERE uqid = ', QUOTE(qid),
                ') 
				SELECT response.*
                FROM response
                INNER JOIN distinct_qid
                ON response.question_id = distinct_qid.question_id
                '
            );
        -- If passed a question ID, identify the uqid associated with that question ID and get all responses for the questions linked to the uqid
        ELSE

			SET @question_query = CONCAT(
				'WITH
                distinct_uqid AS (
					SELECT DISTINCT uqid
                    FROM pir_question_links.linked
                    WHERE question_id = ', QUOTE(qid),
                '),
                distinct_qid AS (
					SELECT DISTINCT question_id
                    FROM pir_question_links.linked
                    INNER JOIN distinct_uqid
                    ON pir_question_links.linked.uqid = distinct_uqid.uqid
				)
                SELECT response.*
                FROM response
                INNER JOIN distinct_qid
                ON response.question_id = distinct_qid.question_id
                '
			);
        
        END IF;
    -- If passed a question ID, get all responses for the specified question ID
	ELSE
		
        SET @question_query = CONCAT(
			'SELECT * ',
            'FROM response ',
            'WHERE question_id = ', QUOTE(qid), ' '
        );
        
	END IF;

	-- Prepare and execute the query    
    SELECT @question_query;
    
    PREPARE statement FROM @question_query;
    EXECUTE statement;
    DEALLOCATE PREPARE statement;

END //

DELIMITER ;