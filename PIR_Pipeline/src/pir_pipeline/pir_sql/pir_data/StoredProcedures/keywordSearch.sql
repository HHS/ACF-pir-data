-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This stored procedure queries a table based on a keyword search in a specified column.
-- Parameters:
--   IN tab varchar(25) - The table to search in.
--   IN col VARCHAR(100) - The column to search in.
--   IN string TEXT - The keyword to search for.
--   IN exact INT - Whether to search for an exact match (1) or a partial match (0).
-- Returns: None
-- Example: CALL pir_data.keywordSearch('question', 'question_name', 'total cumulative', 0);
-- =============================================
DROP PROCEDURE IF EXISTS pir_data.keywordSearch;
DELIMITER //

CREATE PROCEDURE pir_data.keywordSearch(
	IN tab varchar(25), 
    IN col VARCHAR(100), 
    IN string TEXT, 
    IN exact INT
)
BEGIN

    -- Query is an exact match if exact = 1, 
    -- otherwise it is a partial match using regex
    IF exact = 1 THEN
        SET @q = CONCAT(
            'SELECT * ',
            'FROM ', tab,
            ' WHERE ', col, ' = ', QUOTE(string)
        );
    ELSE
        SET @q = CONCAT(
            'SELECT * ',
            'FROM ', tab,
            ' WHERE ', col, ' REGEXP ', QUOTE(string)
        );
    END IF;

    -- Prepare and execute the query
    PREPARE stmt from @q;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

END //
DELIMITER ;