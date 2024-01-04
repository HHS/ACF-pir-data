DELIMITER //

CREATE PROCEDURE reviewUnlinked(IN qid VARCHAR(255))
BEGIN

SET @qid_list = (
	SELECT JSON_KEYS(proposed_link)
	FROM unlinked
	WHERE question_id = qid
);

SELECT `year`, question_id, question_number, question_name, question_text, section
FROM unlinked 
WHERE 
	JSON_CONTAINS(@qid_list, JSON_ARRAY(question_id)) OR
    question_id = qid
UNION
SELECT `year`, question_id, question_number, question_name, question_text, section
FROM linked
WHERE JSON_CONTAINS(@qid_list, JSON_ARRAY(question_id))
;

END //
DELIMITER ;