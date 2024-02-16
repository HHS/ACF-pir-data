DELIMITER //
CREATE PROCEDURE truncateAll()
BEGIN
    truncate table linked;
    truncate table unlinked;
END //
DELIMITER ;