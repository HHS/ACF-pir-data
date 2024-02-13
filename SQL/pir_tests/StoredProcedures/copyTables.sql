DROP PROCEDURE IF EXISTS pir_tests.copyTables;

DELIMITER //

CREATE PROCEDURE pir_tests.copyTables(
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
		SET @create_stmt = CONCAT(
			'CREATE TABLE pir_tests.', @extract, ' AS ',
            'SELECT * ',
            'FROM ', sname, '.', @extract
        );
        SELECT @create_stmt;
        PREPARE statement FROM @create_stmt;
        EXECUTE statement;
        DEALLOCATE PREPARE statement;
        SET ind = Locate(',', tabs) + 1;
        SET tabs = TRIM(SUBSTR(tabs, ind));
    END WHILE;
    
END //

DELIMITER ;