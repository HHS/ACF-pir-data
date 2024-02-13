DROP PROCEDURE IF EXISTS pir_data_test.getQuestion;

DELIMITER //

CREATE PROCEDURE pir_data_test.getQuestion(
	IN qid VARCHAR(255),
    IN kind VARCHAR(12)
)
BEGIN
	
    IF kind = 'uqid' THEN

		SET @view_query = CONCAT(
			'SELECT a.* ',
			'FROM response a ',
			'INNER JOIN (
				SELECT DISTINCT question_id
				FROM question_links.linked b
				INNER JOIN (
					SELECT DISTINCT uqid 
					FROM question_links.linked 
					WHERE question_id = "', qid, '" ',
				') c
				ON b.uqid = c.uqid
			) d
			ON a.question_id = d.question_id
			'
		);
        
	ELSE
		
        SET @view_query = CONCAT(
			'SELECT * ',
            'FROM response ',
            'WHERE question_id = "', qid, '"'
        );
        
	END IF;
        
    SELECT @view_query;
    
    PREPARE statement FROM @view_query;
    EXECUTE statement;
    DEALLOCATE PREPARE statement;

END //

DELIMITER ;