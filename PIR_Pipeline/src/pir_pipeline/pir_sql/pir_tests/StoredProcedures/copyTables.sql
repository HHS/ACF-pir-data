DROP PROCEDURE IF EXISTS pir_tests.copyTables;

DELIMITER //

CREATE PROCEDURE pir_tests.copyTables(
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
    copy_loop: LOOP
        FETCH table_names INTO tname;
        IF done THEN
            LEAVE copy_loop;
        END IF;
        
        -- Create Table
        SET @create_query = CONCAT('CREATE TABLE ', 'pir_tests.', tname, ' LIKE ', sch_name, '.', tname);
        PREPARE create_stmt FROM @create_query;
        EXECUTE create_stmt;
        DEALLOCATE PREPARE create_stmt;
        
        -- Insert data into table
        SET @insert_query = CONCAT('INSERT INTO ', 'pir_tests.', tname, ' SELECT * FROM ', sch_name, '.', tname);
        PREPARE insert_stmt FROM @insert_query;
        EXECUTE insert_stmt;
        DEALLOCATE PREPARE insert_stmt;
        
    END LOOP copy_loop;
    CLOSE table_names;
END //

DELIMITER ;