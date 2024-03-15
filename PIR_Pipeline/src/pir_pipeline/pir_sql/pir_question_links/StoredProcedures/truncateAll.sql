DROP PROCEDURE IF EXISTS pir_question_links.truncateAll;

DELIMITER //
CREATE PROCEDURE pir_question_links.truncateAll()
BEGIN
    truncate table linked;
    truncate table unlinked;
END //
DELIMITER ;