DROP FUNCTION IF EXISTS minYearLinked;
DROP FUNCTION IF EXISTS maxYearLinked;

DELIMITER //
CREATE FUNCTION minYearLinked ()
RETURNS INT DETERMINISTIC
BEGIN

    DECLARE min_year INT DEFAULT 0;
    SET min_year = (SELECT min(year) FROM linked);
    return min_year;

END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION maxYearLinked ()
RETURNS INT DETERMINISTIC
BEGIN

    DECLARE max_year INT DEFAULT 0;
    SET max_year = (SELECT min(year) FROM linked);
    return max_year;

END //
DELIMITER ;

CREATE OR REPLACE VIEW intermittent_link_v AS
SELECT DISTINCT a.uqid, 1 AS intermittent_link
FROM linked a
RIGHT JOIN (
    SELECT uqid
    FROM linked
    GROUP BY uqid
    HAVING min(year) != minYearLinked() and max(year) != maxYearLinked()
) b
ON a.uqid = b.uqid
ORDER BY uqid
;