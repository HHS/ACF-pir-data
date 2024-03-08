
DROP PROCEDURE IF EXISTS pir_data.getProgramLevelData;

-- The DELIMITER statement changes the default delimiter from ';' to '//' for the subsequent CREATE PROCEDURE statement.
DELIMITER //

-- It takes two parameters: col (the column name) and val (the value to search for in the column).
CREATE PROCEDURE pir_data.getProgramLevelData(
    IN col TEXT, IN val TEXT
)
BEGIN
    -- Declare and initialize variables.
    DECLARE where_cond TEXT DEFAULT '';
    
    -- Prepend 'resp.' to the column name for qualification.
    SET col = CONCAT('resp.', col);
    
    -- Construct the WHERE condition based on the provided column and value.
    SET where_cond = CONCAT('WHERE ', col, ' = ', QUOTE(val));
    
    -- Construct the SQL query dynamically based on the provided conditions.
    SET @prg_query = CONCAT(
        '
        SELECT prg.program_name, prg.grant_number, prg.program_number, prg.program_type, resp.question_id, resp.answer, resp.`year`
        FROM pir_data.response resp
        LEFT JOIN pir_data.program prg
        ON resp.uid = prg.uid AND resp.year = prg.year
        ',
        where_cond, ' ',
        'ORDER BY prg.grant_number, prg.program_number, prg.program_type, resp.year'
    );
    
    -- Display the constructed query for debugging purposes.
    SELECT @prg_query;
    
    -- Prepare, execute, and deallocate the dynamically generated SQL statement.
    PREPARE statement FROM @prg_query;
    EXECUTE statement;
    DEALLOCATE PREPARE statement;
    
END //

-- Resetting the delimiter back to ';' for subsequent SQL statements.
DELIMITER ;
