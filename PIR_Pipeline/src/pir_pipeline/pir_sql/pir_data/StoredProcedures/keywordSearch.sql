
DROP PROCEDURE IF EXISTS pir_data.keywordSearch;

-- Change the delimiter to allow the creation of the procedure with multiple statements.
DELIMITER //

-- Create the 'keywordSearch' stored procedure.
CREATE PROCEDURE pir_data.keywordSearch(
    IN tab VARCHAR(25), -- Input parameter: the table name to search within.
    IN col VARCHAR(100), -- Input parameter: the column name to search within.
    IN string TEXT, -- Input parameter: the string to search for.
    IN exact INT -- Input parameter: specifies whether to perform an exact match (1) or a regular expression search (0).
)
BEGIN
    -- Check if exact match is required.
    IF exact = 1 THEN
        -- If exact match is required, build a SELECT query with the provided table, column, and string.
        SET @q = CONCAT(
            'SELECT * ',
            'FROM ', tab,
            ' WHERE ', col, ' = ', QUOTE(string) -- Use QUOTE() to handle string values properly.
        );
    ELSE
        -- If exact match is not required, build a SELECT query with the provided table, column, and string using REGEXP for pattern matching.
        SET @q = CONCAT(
            'SELECT * ',
            'FROM ', tab,
            ' WHERE ', col, ' REGEXP ', QUOTE(string) -- Use QUOTE() to handle string values properly.
        );
    END IF;

    -- Prepare the dynamically generated query.
    PREPARE stmt FROM @q;
    -- Execute the prepared statement.
    EXECUTE stmt;
    -- Deallocate the prepared statement to release resources.
    DEALLOCATE PREPARE stmt;
END //

-- Reset the delimiter back to semicolon.
DELIMITER ;
