DROP FUNCTION IF EXISTS pir_question_links.maxYearLinked;

DELIMITER //
CREATE FUNCTION pir_question_links.maxYearLinked ()
RETURNS INT DETERMINISTIC
BEGIN

    DECLARE max_year INT DEFAULT 0;
    SET max_year = (SELECT min(year) FROM linked);
    return max_year;

END //
DELIMITER ;