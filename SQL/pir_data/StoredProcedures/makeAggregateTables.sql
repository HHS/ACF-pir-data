DROP PROCEDURE IF EXISTS makeAggregateTables;

DELIMITER //

CREATE PROCEDURE makeAggregateTables()
BEGIN

	DECLARE levels JSON DEFAULT '["national", "program_state", "region", "grant_number", "grant_number, program_type"]';
    DECLARE lvl VARCHAR(100) DEFAULT '';
    DECLARE i INT DEFAULT 0;
    
    WHILE i < JSON_LENGTH(levels) DO
		SET lvl = JSON_EXTRACT(levels, CONCAT('$[', i, ']'));
        CALL aggregateTable(JSON_UNQUOTE(lvl));
        SET i = i + 1;
    END WHILE;

END //

DELIMITER ;