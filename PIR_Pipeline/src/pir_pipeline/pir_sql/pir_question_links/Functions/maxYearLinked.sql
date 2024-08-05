-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This function returns the maximum year from the linked table.
-- Parameters: None
-- Returns: The maximum year from the linked table.
-- Example: SELECT pir_question_links.maxYearLinked();
-- =============================================
DROP FUNCTION IF EXISTS pir_question_links.maxYearLinked;

DELIMITER //
CREATE FUNCTION pir_question_links.maxYearLinked ()
RETURNS INT DETERMINISTIC
BEGIN

    DECLARE max_year INT DEFAULT 0;
    SET max_year = (SELECT max(year) FROM linked);
    return max_year;

END //
DELIMITER ;