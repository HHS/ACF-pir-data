-- Retrieves a question based on either 'uqid' or 'question_id'

DROP PROCEDURE IF EXISTS pir_data.getQuestion;

-- The DELIMITER statement changes the default delimiter from ';' to '//' for the subsequent CREATE PROCEDURE statement.
DELIMITER //

CREATE PROCEDURE pir_data.getQuestion(
	IN qid VARCHAR(255),   -- Input parameter for question ID or user question ID
    IN kind VARCHAR(12)    -- Input parameter specifying the type of ID ('uqid' or 'question_id')
)
BEGIN
	-- Condition to handle when kind is 'uqid'
    IF kind = 'uqid' THEN
	
		-- Condition to check if the provided qid contains a '-' indicating it's a user question ID
		IF INSTR(qid, "-") > 0 THEN
        
			-- Constructing the SQL query dynamically to retrieve responses for linked questions
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
        
        ELSE
			-- Constructing the SQL query dynamically to retrieve responses for linked questions
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
        
	-- Condition to handle when kind is not 'uqid'
	ELSE
		
        -- Constructing the SQL query dynamically to retrieve responses for a specific question ID
        SET @question_query = CONCAT(
			'SELECT * ',
            'FROM response ',
            'WHERE question_id = "', qid, '"'
        );
        
	END IF;
        
    -- Displaying the constructed SQL query for debugging purposes
    SELECT @question_query;
    
    -- Prepare and execute the dynamically constructed SQL query
    PREPARE statement FROM @question_query;
    EXECUTE statement;
    DEALLOCATE PREPARE statement;

END //

-- Resetting the delimiter back to ';' for subsequent SQL statements.
DELIMITER ;
