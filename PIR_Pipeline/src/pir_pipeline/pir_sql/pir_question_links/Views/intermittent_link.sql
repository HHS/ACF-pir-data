DROP FUNCTION IF EXISTS pir_question_links.minYearLinked;
DROP FUNCTION IF EXISTS pir_question_links.maxYearLinked;

DELIMITER //
CREATE FUNCTION pir_question_links.minYearLinked ()
RETURNS INT DETERMINISTIC
BEGIN

    DECLARE min_year INT DEFAULT 0;
    SET min_year = (SELECT min(year) FROM linked);
    return min_year;

END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION pir_question_links.maxYearLinked ()
RETURNS INT DETERMINISTIC
BEGIN

    DECLARE max_year INT DEFAULT 0;
    SET max_year = (SELECT min(year) FROM linked);
    return max_year;

END //
DELIMITER ;

CREATE OR REPLACE VIEW pir_question_links.intermittent_link_v AS
SELECT DISTINCT a.uqid, 1 AS intermittent_link
FROM pir_question_links.linked a
RIGHT JOIN (
    SELECT uqid
    FROM pir_question_links.linked
    GROUP BY uqid
    HAVING min(year) != pir_question_links.minYearLinked() and max(year) != pir_question_links.maxYearLinked()
) b
ON a.uqid = b.uqid
ORDER BY uqid
;