-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: Concatenate's a series of column names with AND to create a syntactically correct where condition.
-- Parameters:
--   cols VARCHAR(100) - A comma-separated list of column names.
-- Returns: A WHERE condition for the columns.
-- Example: SELECT pir_data.aggregateWhereCondition('question_id, answer, year');
-- =============================================
DROP FUNCTION IF EXISTS pir_data.aggregateWhereCondition;

DELIMITER //

CREATE FUNCTION pir_data.aggregateWhereCondition(cols VARCHAR(100))
RETURNS TEXT DETERMINISTIC
BEGIN

    -- Declare variables
	DECLARE where_cond TEXT DEFAULT '';
    DECLARE extract VARCHAR(100) DEFAULT '';
    DECLARE ind INT DEFAULT 0;
    
    -- Loop through the columns and generate the WHERE condition
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