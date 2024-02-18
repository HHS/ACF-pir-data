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
