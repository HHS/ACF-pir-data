DROP PROCEDURE IF EXISTS pir_tests.dropTables;

DELIMITER //

CREATE PROCEDURE pir_tests.dropTables(
    IN sch_name VARCHAR(50)
)
BEGIN
	DECLARE tname VARCHAR(64);
    DECLARE done INTEGER DEFAULT 0;
    DECLARE table_names CURSOR FOR
        SELECT `table_name`
        FROM information_schema.tables
        WHERE table_schema = sch_name AND table_type = "BASE TABLE";
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    OPEN table_names;
    drop_loop: LOOP
        FETCH table_names INTO tname;
        IF done THEN
            LEAVE drop_loop;
        END IF;
        SET @drop_query = CONCAT('DROP TABLE', ' pir_tests.', tname);
        PREPARE drop_stmt FROM @drop_query;
        EXECUTE drop_stmt;
        DEALLOCATE PREPARE drop_stmt;
    END LOOP drop_loop;
    CLOSE table_names;
END //

DELIMITER ;