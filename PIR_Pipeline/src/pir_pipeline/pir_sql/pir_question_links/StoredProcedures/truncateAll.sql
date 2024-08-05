-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This stored procedure truncates the linked and unlinked tables.
-- Parameters: None
-- Returns: None
-- Example: CALL pir_question_links.truncateAll();
-- =============================================
DROP PROCEDURE IF EXISTS pir_question_links.truncateAll;

DELIMITER //
CREATE PROCEDURE pir_question_links.truncateAll()
BEGIN
    truncate table linked;
    truncate table unlinked;
END //
DELIMITER ;