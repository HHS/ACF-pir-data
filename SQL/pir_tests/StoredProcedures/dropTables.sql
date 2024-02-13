DROP PROCEDURE IF EXISTS pir_tests.dropTables;

DELIMITER //

CREATE PROCEDURE pir_tests.dropTables (
	IN sname TEXT
)
BEGIN

	DECLARE ind INT DEFAULT 0;
    DECLARE tabs TEXT DEFAULT '';

	SET tabs = (
		SELECT GROUP_CONCAT(`TABLE_NAME` SEPARATOR ',')
        FROM information_schema.tables
        WHERE TABLE_SCHEMA = sname
    );
    SELECT tabs;
    
    SET ind = Locate(',', tabs) + 1;
    WHILE ind != 1 DO
		SET @extract = SUBSTRING_INDEX(tabs, ',', 1);
		SET @drop_stmt = CONCAT(
			'DROP TABLE pir_tests.', @extract
        );
        SELECT @drop_stmt;
        PREPARE statement FROM @drop_stmt;
        EXECUTE statement;
        DEALLOCATE PREPARE statement;
        SET ind = Locate(',', tabs) + 1;
        SET tabs = TRIM(SUBSTR(tabs, ind));
    END WHILE;

END //

DELIMITER ;