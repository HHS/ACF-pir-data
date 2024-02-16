DROP FUNCTION IF EXISTS aggregateWhereCondition;

DELIMITER //

CREATE FUNCTION aggregateWhereCondition(cols VARCHAR(100))
RETURNS TEXT DETERMINISTIC
BEGIN

	DECLARE where_cond TEXT DEFAULT '';
    DECLARE extract VARCHAR(100) DEFAULT '';
    DECLARE ind INT DEFAULT 0;
    
    WHILE ind != 1 DO
		SET extract = SUBSTRING_INDEX(cols, ',', 1);
        IF where_cond = '' THEN
			SET where_cond = CONCAT(where_cond, ' ', extract, ' IS NOT NULL');
		ELSE
			SET where_cond = CONCAT(where_cond, ' AND ', extract, ' IS NOT NULL');
		END IF;
        SET ind = Locate(',', cols) + 1;
        SET cols = TRIM(SUBSTR(cols, ind));
    END WHILE;
	RETURN where_cond;

END //

DELIMITER ;