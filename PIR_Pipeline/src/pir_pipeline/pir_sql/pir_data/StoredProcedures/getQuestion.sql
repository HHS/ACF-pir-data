DROP PROCEDURE IF EXISTS pir_data.getQuestion;

DELIMITER //

CREATE PROCEDURE pir_data.getQuestion(
	IN qid VARCHAR(255),
    IN kind VARCHAR(12)
)
BEGIN
	
    IF kind = 'uqid' THEN
	
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
        
	ELSE
		
        SET @question_query = CONCAT(
			'SELECT * ',
            'FROM response ',
            'WHERE question_id = "', qid, '"'
        );
        
	END IF;
        
    SELECT @question_query;
    
    PREPARE statement FROM @question_query;
    EXECUTE statement;
    DEALLOCATE PREPARE statement;

END //

DELIMITER ;