-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: Search table, on column, by string. This uses REGEX behind the scenes so some wildcards can be used.
-- Parameters:
--   IN tab varchar(25) - The table to search in.
--   IN col VARCHAR(100) - The column to search in.
--   IN string TEXT - The keyword to search for.
--   IN exact INT - Whether to search for an exact match (1) or a partial match (0).
-- Returns: None
-- Example: CALL pir_question_links.keywordSearch('linked', 'question_name', 'total cumulative', 0);
-- =============================================
DROP PROCEDURE IF EXISTS pir_question_links.keywordSearch;

DELIMITER //

CREATE PROCEDURE pir_question_links.keywordSearch(
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