-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This function returns the minimum year from the linked table.
-- Parameters: None
-- Returns: The minimum year from the linked table.
-- Example: SELECT pir_question_links.minYearLinked();
-- =============================================
DROP FUNCTION IF EXISTS pir_question_links.minYearLinked;

DELIMITER //
CREATE FUNCTION pir_question_links.minYearLinked ()
RETURNS INT DETERMINISTIC
BEGIN

    DECLARE min_year INT DEFAULT 0;
    SET min_year = (SELECT min(year) FROM linked);
    return min_year;

END //
DELIMITER ;
