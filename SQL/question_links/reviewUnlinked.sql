DELIMITER //

CREATE PROCEDURE reviewUnlinked(IN qid VARCHAR(255))
BEGIN

SET @qid_list = (
	SELECT JSON_KEYS(proposed_link)
	FROM unlinked
	WHERE question_id = qid
);

SELECT *
FROM unlinked 
WHERE JSON_CONTAINS(@qid_list, JSON_ARRAY(question_id));

END //
DELIMITER ;

