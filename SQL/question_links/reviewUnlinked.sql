DELIMITER //
CREATE PROCEDURE reviewUnlinked(
    IN targetID varchar(255)
)
BEGIN
    SELECT * 
    FROM unlinked 
    WHERE 
        question_id = targetID
        OR JSON_CONTAINS(
                JSON_KEYS(proposed_link), 
                '[targetID]'
            )
    ;
END //
DELIMITER ;